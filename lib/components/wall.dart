import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';

/// 게임 벽 컴포넌트 클래스
class Wall extends BodyComponent {
  final Vector2 position;
  final Vector2 size;
  final Color color;

  /// 생성자
  /// [position] 벽의 위치
  /// [size] 벽의 크기
  /// [color] 벽의 색상
  Wall({
    required this.position,
    required this.size,
    this.color = const Color(0xFF444444),
  });

  @override
  Body createBody() {
    final bodyDef =
        BodyDef()
          ..position = position
          ..type = BodyType.static;

    final body = world.createBody(bodyDef);

    final shape =
        PolygonShape()..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0.0);

    final fixtureDef =
        FixtureDef(shape)
          ..restitution =
              1.0 // 완전 탄성 충돌
          ..friction = 0.1; // 약간의 마찰

    body.createFixture(fixtureDef);

    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // 중심이 (0,0)인 상자 그리기
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(rect, paint);

    // 테두리 그리기 (조금 밝은 색으로)
    final borderPaint =
        Paint()
          ..color = Color.fromARGB(
            color.alpha,
            (color.red + 30).clamp(0, 255),
            (color.green + 30).clamp(0, 255),
            (color.blue + 30).clamp(0, 255),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05;

    canvas.drawRect(rect, borderPaint);
  }
}
