import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Colors, LinearGradient, Alignment;
import 'dart:math' as math;

/// 벽돌 타입 열거형
enum BrickType {
  /// 일반 벽돌
  normal,

  /// 강화 벽돌
  reinforced,

  /// 특수 능력 벽돌 - 기본
  special,

  /// 폭발성 벽돌 - 주변 벽돌에 데미지
  explosive,

  /// 아이템 드롭 벽돌 - 파워업 아이템 드롭
  powerup,

  /// 이동 벽돌 - 게임 영역에서 움직임
  moving,

  /// 보스 벽돌
  boss,
}

/// 벽돌 효과 이벤트 콜백 시그니처
typedef BrickEffectCallback = void Function(Brick brick, BrickType effectType);

/// 벽돌 컴포넌트 클래스
class Brick extends BodyComponent {
  @override
  final Vector2 position;
  final Vector2 size;
  final int hp;
  final Color color;
  final BrickType type;

  // 효과 콜백
  final BrickEffectCallback? onEffectActivated;

  // 이동 벽돌용 변수
  Vector2? _velocity;
  Vector2? _bounds;
  bool _isMoving = false;

  int _currentHp;
  bool _isDamaged = false;
  double _animationTime = 0;
  final double _hitAnimationDuration = 0.3;
  bool _isDestroying = false;
  double _destroyProgress = 0;

  /// 생성자
  /// [position] 벽돌의 위치
  /// [size] 벽돌의 크기
  /// [hp] 파괴하기 위해 필요한 타격 횟수
  /// [color] 벽돌의 색상
  /// [type] 벽돌의 타입
  /// [onEffectActivated] 특수 효과 발동 시 콜백
  Brick({
    required this.position,
    Vector2? size,
    this.hp = 1,
    Color? color,
    this.type = BrickType.normal,
    this.onEffectActivated,
  }) : size = size ?? Vector2(1.5, 0.6),
       color = color ?? _getColorByType(type, hp),
       _currentHp = hp {
    // 이동 벽돌 타입인 경우 기본 이동 속도 설정
    if (type == BrickType.moving) {
      _isMoving = true;
      _velocity = Vector2(1.0, 0); // 기본적으로 수평 이동
    }
  }

  /// 현재 남아있는 타격 횟수
  int get currentHp => _currentHp;

  /// 파괴 중인지 여부
  bool get isDestroying => _isDestroying;

  /// 이동 벽돌의 영역 제한 설정
  void setBounds(Vector2 bounds) {
    _bounds = bounds;
  }

  /// 이동 벽돌의 속도 설정
  void setVelocity(Vector2 velocity) {
    _velocity = velocity;
  }

  /// 벽돌 타입과 HP에 따른 색상 결정
  static Color _getColorByType(BrickType type, int hp) {
    switch (type) {
      case BrickType.normal:
        // HP에 따라 일반 벽돌 색상 그라데이션 (빨강 → 주황 → 노랑)
        if (hp <= 1) return Colors.red;
        if (hp == 2) return Colors.orange;
        if (hp == 3) return Colors.amber;
        return Colors.deepOrange;

      case BrickType.reinforced:
        // 강화 벽돌은 파란색 계열
        if (hp <= 3) return Colors.lightBlue;
        if (hp <= 5) return Colors.blue;
        return Colors.indigo;

      case BrickType.special:
        // 특수 벽돌은 보라색 계열
        return Colors.purple;

      case BrickType.explosive:
        // 폭발성 벽돌은 빨간색 계열
        return Colors.redAccent;

      case BrickType.powerup:
        // 파워업 벽돌은 노란색/금색 계열
        return Colors.amber.shade600;

      case BrickType.moving:
        // 이동 벽돌은 초록색 계열
        return Colors.greenAccent;

      case BrickType.boss:
        // 보스 벽돌은 짙은 보라색 계열
        return Colors.deepPurple;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = true;
    paint = Paint()..color = _getColorByType(type, hp);
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: _isMoving ? BodyType.kinematic : BodyType.static,
      userData: this,
    );

    final shape =
        PolygonShape()..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(
      shape,
      friction: 0.1,
      restitution: 0.5,
      filter:
          Filter()
            ..categoryBits =
                0x0004 // 벽돌 카테고리
            ..maskBits = 0xFFFF, // 모든 객체와 충돌
    );

    final body = world.createBody(bodyDef);
    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 이동 벽돌 업데이트
    if (_isMoving && _velocity != null && !_isDestroying) {
      final newPosition = body.position + (_velocity! * dt);

      // 경계 체크 및 튕김 처리
      if (_bounds != null) {
        if (newPosition.x - size.x / 2 < -_bounds!.x / 2 ||
            newPosition.x + size.x / 2 > _bounds!.x / 2) {
          _velocity!.x = -_velocity!.x;
        }

        if (newPosition.y - size.y / 2 < -_bounds!.y / 2 ||
            newPosition.y + size.y / 2 > _bounds!.y / 2) {
          _velocity!.y = -_velocity!.y;
        }
      }

      body.setTransform(body.position + (_velocity! * dt), 0);
    }

    // 타격 애니메이션 진행
    if (_isDamaged) {
      _animationTime += dt;
      if (_animationTime >= _hitAnimationDuration) {
        _isDamaged = false;
        _animationTime = 0;
      }
    }

    // 파괴 애니메이션 진행
    if (_isDestroying) {
      _destroyProgress += dt * 2; // 0.5초 동안 진행
      if (_destroyProgress >= 1.0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 파괴 중인 경우 축소 효과
    if (_isDestroying) {
      final scale = 1.0 - _destroyProgress;
      canvas.scale(scale, scale);

      // 회전 효과 추가
      canvas.rotate(_destroyProgress * math.pi * 0.5);

      // 투명도 감소
      _renderBrick(canvas, opacity: 1.0 - _destroyProgress);
      return;
    }

    // 타격 효과 - 약간 확대 및 밝기 변화
    if (_isDamaged) {
      // 사인 곡선을 사용하여 펄스 효과 (0 -> 1 -> 0)
      final pulseAmount = math.sin(
        _animationTime / _hitAnimationDuration * math.pi,
      );
      final scale = 1.0 + pulseAmount * 0.1; // 최대 10% 확대
      canvas.scale(scale, scale);

      // 밝기 증가
      _renderBrick(canvas, brightness: 1.2);
    } else {
      _renderBrick(canvas);
    }
  }

  /// 실제 벽돌 렌더링 로직
  void _renderBrick(
    Canvas canvas, {
    double opacity = 1.0,
    double brightness = 1.0,
  }) {
    final rect = Rect.fromCenter(
      center: Offset(0, 0),
      width: size.x,
      height: size.y,
    );

    // 기본 배경 그리기
    final paint =
        Paint()
          ..color = _adjustColor(color, opacity, brightness)
          ..style = PaintingStyle.fill;

    // 약간의 라운드 모서리 효과
    final radius = Radius.circular(size.y * 0.15);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(rrect, paint);

    // 내부 그라데이션 효과 (위쪽이 더 밝게)
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.2 * opacity),
              Colors.transparent,
            ],
          ).createShader(rect);

    canvas.drawRRect(rrect, gradientPaint);

    // 테두리 그리기
    final borderPaint =
        Paint()
          ..color = _adjustColor(
            color.withBlue(math.min(255, color.blue + 40)),
            opacity,
            brightness,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05;

    canvas.drawRRect(rrect, borderPaint);

    // HP를 시각적으로 표시
    _renderHpIndicator(canvas, rect, opacity, brightness);

    // 특수 벽돌 아이콘 렌더링
    _renderBrickTypeIcon(canvas, rect, opacity, brightness);
  }

  /// HP 표시기 렌더링
  void _renderHpIndicator(
    Canvas canvas,
    Rect rect,
    double opacity,
    double brightness,
  ) {
    // HP가 1이면 표시하지 않음
    if (hp <= 1) return;

    final textPaint = Paint()..color = Colors.white.withOpacity(0.8 * opacity);

    // 작은 점으로 HP 표시
    final dotSize = size.y * 0.15;
    final dotSpacing = dotSize * 1.5;

    // 중앙 기준으로 HP 개수만큼 점 그리기
    final totalWidth =
        (_currentHp * dotSize) + ((_currentHp - 1) * (dotSpacing - dotSize));
    final startX = -totalWidth / 2 + dotSize / 2;

    for (int i = 0; i < _currentHp; i++) {
      final dotX = startX + i * dotSpacing;
      final dotRect = Rect.fromCircle(
        center: Offset(dotX, 0),
        radius: dotSize / 2,
      );
      canvas.drawOval(dotRect, textPaint);
    }
  }

  /// 벽돌 타입별 아이콘 렌더링
  void _renderBrickTypeIcon(
    Canvas canvas,
    Rect rect,
    double opacity,
    double brightness,
  ) {
    // 특수 벽돌 타입만 아이콘 표시
    switch (type) {
      case BrickType.explosive:
        _drawExplosiveIcon(canvas, rect, opacity);
        break;
      case BrickType.powerup:
        _drawPowerupIcon(canvas, rect, opacity);
        break;
      case BrickType.moving:
        _drawMovingIcon(canvas, rect, opacity);
        break;
      case BrickType.boss:
        _drawBossIcon(canvas, rect, opacity);
        break;
      default:
        // 다른 벽돌은 아이콘 없음
        break;
    }
  }

  // 폭발성 벽돌 아이콘
  void _drawExplosiveIcon(Canvas canvas, Rect rect, double opacity) {
    final iconPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.y * 0.05;

    // 폭발 표시 (X자 형태)
    final iconSize = size.y * 0.3;
    canvas.drawLine(
      Offset(-iconSize / 2, -iconSize / 2),
      Offset(iconSize / 2, iconSize / 2),
      iconPaint,
    );
    canvas.drawLine(
      Offset(iconSize / 2, -iconSize / 2),
      Offset(-iconSize / 2, iconSize / 2),
      iconPaint,
    );
  }

  // 파워업 벽돌 아이콘
  void _drawPowerupIcon(Canvas canvas, Rect rect, double opacity) {
    final iconPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.fill;

    // 별 모양 그리기
    final iconSize = size.y * 0.3;
    final starPath = Path();
    final double centerX = 0;
    final double centerY = 0;

    for (int i = 0; i < 5; i++) {
      double angle = -math.pi / 2 + i * 4 * math.pi / 5;
      double x = centerX + math.cos(angle) * iconSize;
      double y = centerY + math.sin(angle) * iconSize;

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }

      angle += 2 * math.pi / 10;
      x = centerX + math.cos(angle) * (iconSize * 0.4);
      y = centerY + math.sin(angle) * (iconSize * 0.4);
      starPath.lineTo(x, y);
    }

    starPath.close();
    canvas.drawPath(starPath, iconPaint);
  }

  // 이동 벽돌 아이콘
  void _drawMovingIcon(Canvas canvas, Rect rect, double opacity) {
    final iconPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.y * 0.05;

    // 움직임을 나타내는 화살표
    final iconSize = size.y * 0.3;

    // 좌우 화살표
    canvas.drawLine(
      Offset(-iconSize / 2, 0),
      Offset(iconSize / 2, 0),
      iconPaint,
    );

    // 화살표 머리
    canvas.drawLine(
      Offset(iconSize / 2, 0),
      Offset(iconSize / 4, -iconSize / 4),
      iconPaint,
    );
    canvas.drawLine(
      Offset(iconSize / 2, 0),
      Offset(iconSize / 4, iconSize / 4),
      iconPaint,
    );

    canvas.drawLine(
      Offset(-iconSize / 2, 0),
      Offset(-iconSize / 4, -iconSize / 4),
      iconPaint,
    );
    canvas.drawLine(
      Offset(-iconSize / 2, 0),
      Offset(-iconSize / 4, iconSize / 4),
      iconPaint,
    );
  }

  // 보스 벽돌 아이콘
  void _drawBossIcon(Canvas canvas, Rect rect, double opacity) {
    final iconPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.y * 0.05;

    // 왕관 모양
    final iconSize = size.y * 0.3;
    final crownPath = Path();

    crownPath.moveTo(-iconSize / 2, iconSize / 4);
    crownPath.lineTo(iconSize / 2, iconSize / 4);
    crownPath.lineTo(iconSize / 4, -iconSize / 4);
    crownPath.lineTo(0, iconSize / 8);
    crownPath.lineTo(-iconSize / 4, -iconSize / 4);
    crownPath.close();

    canvas.drawPath(crownPath, iconPaint);
  }

  /// 색상 조정 (밝기, 투명도)
  Color _adjustColor(Color baseColor, double opacity, double brightness) {
    // 밝기 조정
    int r = math.min(255, (baseColor.red * brightness).round());
    int g = math.min(255, (baseColor.green * brightness).round());
    int b = math.min(255, (baseColor.blue * brightness).round());

    return Color.fromRGBO(r, g, b, opacity);
  }

  /// 벽돌이 타격을 받을 때 호출
  void hit() {
    if (_isDestroying) return;

    _currentHp--;
    _isDamaged = true;
    _animationTime = 0;

    // 타격 효과
    final oldColor = paint.color;
    paint.color = Colors.white;

    // 타이머로 깜빡임 효과
    Future.delayed(const Duration(milliseconds: 50), () {
      if (isMounted) {
        paint.color = oldColor.withOpacity(_currentHp / hp);
      }
    });

    // HP가 0 이하면 파괴
    if (_currentHp <= 0) {
      _isDestroying = true;

      // 특수 효과 발동
      _activateEffect();
    }
  }

  /// 특수 효과 발동
  void _activateEffect() {
    if (onEffectActivated != null) {
      onEffectActivated!(this, type);
    }
  }

  /// 즉시 파괴 (애니메이션 없이)
  void destroyImmediately() {
    removeFromParent();
  }
}
