import 'vector2d.dart';
import 'physics_body.dart';

/// 충돌 정보를 담는 클래스
class Collision {
  final PhysicsBody bodyA;
  final PhysicsBody bodyB;
  final Vector2D normal;
  final double penetration;
  final List<Vector2D> contactPoints;

  Collision({
    required this.bodyA,
    required this.bodyB,
    required this.normal,
    required this.penetration,
    required this.contactPoints,
  });
}

/// 공간 분할을 위한 격자 셀
class GridCell {
  final List<PhysicsBody> bodies = [];
}

// 헬퍼 함수
int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
