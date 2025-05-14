import 'package:flame/components.dart' hide Vector2;
import 'package:flame_forge2d/flame_forge2d.dart';

/// 게임 월드의 경계를 정의하는 컴포넌트
class WorldBoundaries extends Component with HasGameRef<Forge2DGame> {
  // 월드 크기 상수 (10:16 비율)
  static const double _width = 9.0;
  static const double _height = 16.0;

  // 벽 두께
  static const double _wallThickness = 0.2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 왼쪽 벽
    final leftWall = Wall(
      Vector2(-_wallThickness / 2, _height / 2),
      Vector2(_wallThickness, _height + _wallThickness),
    );

    // 오른쪽 벽
    final rightWall = Wall(
      Vector2(_width + _wallThickness / 2, _height / 2),
      Vector2(_wallThickness, _height + _wallThickness),
    );

    // 위쪽 벽
    final topWall = Wall(
      Vector2(_width / 2, -_wallThickness / 2),
      Vector2(_width + _wallThickness, _wallThickness),
    );

    // 아래쪽 벽 (없는 경우 - 공이 떨어질 수 있도록)
    /*
    final bottomWall = Wall(
      Vector2(_width / 2, _height + _wallThickness / 2),
      Vector2(_width + _wallThickness, _wallThickness),
    );
    */

    // 벽 추가
    add(leftWall);
    add(rightWall);
    add(topWall);
    // 아래쪽 벽은 추가하지 않음 - 공이 떨어질 수 있게
    // add(bottomWall);
  }
}

/// 경계 벽 클래스
class Wall extends BodyComponent {
  /// 벽의 위치와 크기
  @override
  final Vector2 position;
  final Vector2 size;

  /// 생성자
  Wall(this.position, this.size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false; // Forge2D의 기본 그리기를 비활성화
  }

  @override
  Body createBody() {
    // 벽 모양 정의
    final shape =
        PolygonShape()..setAsBox(
          size.x / 2, // 너비의 절반
          size.y / 2, // 높이의 절반
          Vector2.zero(), // 중심점 (0,0)
          0.0, // 회전 각도
        );

    // 바디 정의 생성
    final fixtureDef =
        FixtureDef(shape)
          ..restitution =
              1.0 // 완전 탄성 충돌
          ..friction =
              0.0 // 마찰 없음
          ..density = 1000.0; // 고밀도 - 움직이지 않음

    // 정적 바디 생성
    final bodyDef =
        BodyDef()
          ..position = position
          ..type = BodyType.static;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
