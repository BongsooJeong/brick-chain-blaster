import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';

/// 벽돌 컴포넌트 클래스
class Brick extends BodyComponent {
  final Vector2 position;
  final Vector2 size;
  final int hitPoints;
  final Color color;

  int _currentHitPoints;

  /// 생성자
  /// [position] 벽돌의 위치
  /// [size] 벽돌의 크기
  /// [hitPoints] 파괴하기 위해 필요한 타격 횟수
  /// [color] 벽돌의 색상
  Brick({
    required this.position,
    required this.size,
    this.hitPoints = 1,
    this.color = const Color(0xFFFF0000),
  }) : _currentHitPoints = hitPoints;

  /// 현재 남아있는 타격 횟수
  int get currentHitPoints => _currentHitPoints;

  @override
  Body createBody() {
    final bodyDef =
        BodyDef()
          ..type = BodyType.static
          ..position = position;

    final body = world.createBody(bodyDef);

    final shape =
        PolygonShape()..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0.0);

    final fixtureDef =
        FixtureDef(shape)
          ..density = 1.0
          ..friction = 0.3
          ..restitution = 0.5;

    body.createFixture(fixtureDef);

    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromCenter(
      center: Offset(0, 0),
      width: size.x,
      height: size.y,
    );

    // 기본 배경 그리기
    final paint = Paint()..color = color.withOpacity(0.8);

    canvas.drawRect(rect, paint);

    // 테두리 그리기
    final borderPaint =
        Paint()
          ..color = color.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05;

    canvas.drawRect(rect, borderPaint);

    // 타격 횟수를 표시할 경우 텍스트 그리기 (추후 구현)
  }

  /// 벽돌에 타격을 가했을 때 호출
  bool hit() {
    _currentHitPoints--;
    if (_currentHitPoints <= 0) {
      removeFromParent();
      return true; // 파괴됨
    }
    return false; // 아직 파괴되지 않음
  }
}
