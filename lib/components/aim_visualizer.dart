import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 공 발사 조준선 시각화 컴포넌트
class AimVisualizer extends Component with HasGameRef<BrickChainGame> {
  /// 시작 위치
  Vector2 startPosition;

  /// 조준 방향
  Vector2 direction;

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
  final void Function(Vector2 direction)? shootCallback;

  /// 시각화 활성화 여부
  bool isActive = false;

  /// 기본 Paint 객체
  late final Paint _paint;

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
  }) : direction = direction ?? Vector2(0, -1) {
    _paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
  }

  /// 드래그 시작 처리
  void onDragStart(Vector2 worldPosition) {
    isActive = true;
    final dragDirection = worldPosition - startPosition;

    // 아래쪽으로 발사하지 못하도록 제한 (y가 양수로 증가하는 방향이 아래쪽)
    if (dragDirection.y > 0) {
      dragDirection.y = 0;
    }

    updateDirection(dragDirection);
  }

  /// 드래그 업데이트 처리
  void onDragUpdate(Vector2 worldPosition) {
    if (!isActive) return;

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

    // 발사 콜백 호출
    if (direction.length > 0.1 && shootCallback != null) {
      shootCallback!(direction.clone());
    }

    isActive = false;
  }

  /// 조준 방향 업데이트
  void updateDirection(Vector2 newDirection) {
    if (newDirection.length > 0.1) {
      direction = newDirection.normalized();
    }
  }

  @override
  void render(Canvas canvas) {
    if (direction.length < 0.1 || !isActive) return;

    // 방향 벡터를 정규화하고 원하는 길이로 스케일
    final scaledDirection = direction.normalized().scaled(lineLength);
    final endPoint = startPosition + scaledDirection;

    if (isDashed) {
      _drawDashedLine(canvas, startPosition, endPoint);
    } else {
      canvas.drawLine(startPosition.toOffset(), endPoint.toOffset(), _paint);
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

        canvas.drawLine(segmentStart.toOffset(), segmentEnd.toOffset(), _paint);
      }

      currentDistance += segmentLength;
      drawLine = !drawLine;
    }
  }
}
