import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';
import 'package:brick_chain_blaster/managers/ball_manager.dart';
import 'dart:math' as math;

typedef ShootCallback = void Function(Vector2 direction);
typedef CancelCallback = void Function();

/// 공 발사 조준선 시각화 컴포넌트
class AimVisualizer extends Component with HasGameRef<BrickChainGame> {
  /// 시작 위치
  Vector2 startPosition;

  /// 조준 방향
  Vector2 direction;

  /// 현재 조준 위치 (드래그 위치 추적용)
  Vector2? aimPosition;

  /// 선 길이
  final double lineLength;

  /// 선 색상
  final Color lineColor;

  /// 선 두께
  final double strokeWidth;

  /// 점선 패턴 사용 여부
  final bool isDashed;

  /// 대시 길이 (점선인 경우)
  final double dashLength;

  /// 대시 간격 (점선인 경우)
  final double dashGap;

  /// 발사 콜백 함수 - 발사 방향을 전달
  final ShootCallback? shootCallback;

  /// 발사 취소 콜백 함수
  final CancelCallback? cancelCallback;

  /// 시각화 활성화 여부
  bool isActive = false;

  /// 볼 매니저 참조
  final BallManager ballManager;

  /// 발사 준비 중인지 상태
  bool isPrimed = false;

  /// 애니메이션 타이머
  double _animationTimer = 0.0;

  /// 물결 효과 애니메이션 타이머
  double _rippleTimer = 0.0;

  /// 물결 효과 표시 여부
  bool _showRipple = false;

  /// 기본 Paint 객체
  late final Paint _paint;

  /// 체인 볼 Paint 객체
  late final Paint _ballPaint;

  /// 체인 볼 하이라이트 Paint 객체
  late final Paint _ballHighlightPaint;

  /// 물결 효과 Paint 객체
  late final Paint _ripplePaint;

  /// 생성자
  AimVisualizer({
    required this.startPosition,
    Vector2? direction,
    this.lineLength = 5.0,
    this.lineColor = const Color(0xAAFFFFFF),
    this.strokeWidth = 0.1,
    this.isDashed = true,
    this.dashLength = 0.3,
    this.dashGap = 0.2,
    this.shootCallback,
    this.cancelCallback,
    required this.ballManager,
  }) : direction = direction ?? Vector2(0, -1) {
    _paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    _ballPaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.fill;

    _ballHighlightPaint =
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.fill;

    _ripplePaint =
        Paint()
          ..color = const Color(0x40FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05;
  }

  /// 드래그 시작 처리
  void onDragStart(Vector2 worldPosition) {
    isActive = true;
    aimPosition = worldPosition;
    final dragDirection = worldPosition - startPosition;

    // 아래쪽으로 발사하지 못하도록 제한 (y가 양수로 증가하는 방향이 아래쪽)
    if (dragDirection.y > 0) {
      dragDirection.y = 0;
    }

    updateDirection(dragDirection);

    // 발사 충전 시작
    ballManager.startCharging();
  }

  /// 드래그 업데이트 처리
  void onDragUpdate(Vector2 worldPosition) {
    if (!isActive) return;

    aimPosition = worldPosition;
    final dragDirection = worldPosition - startPosition;

    // 아래쪽으로 발사하지 못하도록 제한
    if (dragDirection.y > 0) {
      dragDirection.y = 0;
    }

    updateDirection(dragDirection);
  }

  /// 드래그 종료 처리
  void onDragEnd() {
    if (!isActive) return;

    // 먼저 충전 완료
    ballManager.primeForFiring();

    // 발사 콜백 호출 (짧은 지연 후 발사)
    if (direction.length > 0.1 && shootCallback != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (isActive) {
          isActive = false;
          shootCallback!(direction.clone());
        }
      });
    } else {
      isActive = false;
    }
  }

  /// 드래그 취소 처리
  void onDragCancel() {
    if (!isActive) return;

    isActive = false;

    // 충전 취소
    ballManager.cancelCharging();

    // 취소 콜백 호출
    if (cancelCallback != null) {
      cancelCallback!();
    }
  }

  /// 조준 방향 업데이트
  void updateDirection(Vector2 newDirection) {
    if (newDirection.length > 0.1) {
      direction = newDirection.normalized();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 애니메이션 타이머 업데이트
    _animationTimer += dt;

    // 발사 준비 상태 확인 및 갱신
    isPrimed = ballManager.isPrimed;

    // 발사 준비 중이면 물결 효과 표시
    if (isPrimed) {
      _rippleTimer += dt * 2.0;

      // 주기적으로 물결 효과 표시 (0.5초마다)
      if (_rippleTimer > 0.5) {
        _showRipple = true;
        _rippleTimer = 0;
      } else if (_rippleTimer > 0.25) {
        _showRipple = false;
      }
    } else {
      _showRipple = false;
      _rippleTimer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    // 항상 체인의 모든 공들을 시각화
    _renderBallChain(canvas);

    // 조준선은 활성화된 경우에만 표시
    if (direction.length >= 0.1 && isActive) {
      _renderAimLine(canvas);
    }

    // 발사 준비 상태이면 특수 효과 표시
    if (isPrimed) {
      _renderPrimedEffects(canvas);
    }
  }

  /// 월드 좌표를 화면 좌표로 변환
  Vector2 _convertWorldToScreen(Vector2 worldPosition) {
    final position = worldPosition.clone();
    final zoom = gameRef.camera.viewfinder.zoom;
    final cameraPosition = gameRef.camera.viewfinder.position;
    final size = gameRef.size;
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // 월드 -> 화면 변환 (월드 -> 카메라 상대 좌표 -> 화면 좌표)
    position.x = (position.x - cameraPosition.x) * zoom + centerX;
    position.y = (position.y - cameraPosition.y) * zoom + centerY;
    return position;
  }

  /// 체인의 모든 공을 시각화
  void _renderBallChain(Canvas canvas) {
    // 볼 매니저로부터 체인 내 모든 공 위치 가져오기
    final ballPositions = ballManager.getChainedBallPositions();
    final vibrationOffset = ballManager.getVibrationOffset();
    final ballRadius = ballManager.ballRadius;

    // 모든 공 그리기
    for (int i = 0; i < ballPositions.length; i++) {
      final pos = ballPositions[i];

      // 첫 번째 공은 진동 효과 적용
      final adjustedPos = (i == 0) ? pos + vibrationOffset : pos;

      // 월드 좌표계로 변환
      final transform = _convertWorldToScreen(adjustedPos);

      // 체인에서의 위치에 따라 크기와 투명도 조정
      final opacity = 1.0 - (i * 0.15).clamp(0.0, 0.7);
      final size = ballRadius * (1.0 - (i * 0.05).clamp(0.0, 0.3));

      // 공 그리기
      _ballPaint.color = const Color(0xFFFFFFFF).withOpacity(opacity);
      canvas.drawCircle(
        transform.toOffset(),
        size * gameRef.camera.viewfinder.zoom,
        _ballPaint,
      );

      // 첫 번째 공에만 하이라이트 효과 추가
      if (i == 0) {
        _ballHighlightPaint.color = const Color(0xAAFFFFFF);
        canvas.drawCircle(
          transform.toOffset() +
              Offset(
                -size * 0.3 * gameRef.camera.viewfinder.zoom,
                -size * 0.3 * gameRef.camera.viewfinder.zoom,
              ),
          size * 0.3 * gameRef.camera.viewfinder.zoom,
          _ballHighlightPaint,
        );
      }
    }
  }

  /// 조준선 그리기
  void _renderAimLine(Canvas canvas) {
    // 진동 효과 적용
    final adjustedStart = startPosition + ballManager.getVibrationOffset();

    // 방향 벡터를 정규화하고 원하는 길이로 스케일
    final scaledDirection = direction.normalized().scaled(lineLength);
    final endPoint = adjustedStart + scaledDirection;

    if (isDashed) {
      _drawDashedLine(canvas, adjustedStart, endPoint);
    } else {
      // 월드 좌표계로 변환
      final startTransform = _convertWorldToScreen(adjustedStart);
      final endTransform = _convertWorldToScreen(endPoint);

      // 화면 좌표로 변환된 좌표로 그리기
      canvas.drawLine(
        startTransform.toOffset(),
        endTransform.toOffset(),
        _paint,
      );
    }
  }

  /// 발사 준비 상태 특수 효과 그리기
  void _renderPrimedEffects(Canvas canvas) {
    // 발사 위치에 물결 효과 그리기
    if (_showRipple) {
      // 진동 효과 적용
      final adjustedStart = startPosition + ballManager.getVibrationOffset();
      final transform = _convertWorldToScreen(adjustedStart);

      // 물결 반지름 (펄스 효과)
      final rippleRadius =
          ballManager.ballRadius *
          2.0 *
          (1.0 + math.sin(_animationTimer * 10)) *
          gameRef.camera.viewfinder.zoom;

      _ripplePaint.color = const Color(0x40FFFFFF);
      canvas.drawCircle(transform.toOffset(), rippleRadius, _ripplePaint);
    }
  }

  /// 점선 그리기
  void _drawDashedLine(Canvas canvas, Vector2 start, Vector2 end) {
    final totalDistance = start.distanceTo(end);
    final normalizedDirection = (end - start).normalized();

    double currentDistance = 0;
    bool drawLine = true;

    while (currentDistance < totalDistance) {
      final segmentLength = drawLine ? dashLength : dashGap;

      if (drawLine) {
        final segmentStart =
            start + normalizedDirection.scaled(currentDistance);
        double remainingLength = totalDistance - currentDistance;

        if (remainingLength > dashLength) {
          remainingLength = dashLength;
        }

        final segmentEnd =
            start +
            normalizedDirection.scaled(currentDistance + remainingLength);

        // 월드 좌표계로 변환
        final startTransform = _convertWorldToScreen(segmentStart);
        final endTransform = _convertWorldToScreen(segmentEnd);

        // 화면 좌표로 변환된 좌표로 그리기
        canvas.drawLine(
          startTransform.toOffset(),
          endTransform.toOffset(),
          _paint,
        );
      }

      currentDistance += segmentLength;
      drawLine = !drawLine;
    }
  }
}
