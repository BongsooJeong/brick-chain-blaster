import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';

/// 벽돌 컴포넌트 클래스
class Brick extends BodyComponent {
  final Vector2 position;
  final Vector2 size;
  final int hp;
  final Color color;

  int _currentHp;

  /// 생성자
  /// [position] 벽돌의 위치
  /// [size] 벽돌의 크기
  /// [hp] 파괴하기 위해 필요한 타격 횟수
  /// [color] 벽돌의 색상
  Brick({
    required this.position,
    required this.size,
    this.hp = 1,
    this.color = const Color(0xFFFF0000),
  }) : _currentHp = hp;

  /// 현재 남아있는 타격 횟수
  int get currentHp => _currentHp;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false; // Forge2D의 기본 그리기를 비활성화하고 직접 렌더링
  }

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

  /// 벽돌이 타격을 받을 때 호출
  void hit() {
    _currentHp--;
    if (_currentHp <= 0) {
      removeFromParent();
    }
  }
}
