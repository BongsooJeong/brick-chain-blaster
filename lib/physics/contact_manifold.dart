import 'vector2d.dart';
import 'physics_body.dart';

/// 충돌 접촉 매니폴드 클래스
///
/// 두 물체 간의 충돌 접촉점에 대한 세부 정보를 저장하고
/// 충격 기반 솔버에서 필요한 정보를 유지합니다.
class ContactManifold {
  /// 충돌한 첫 번째 물체
  final PhysicsBody bodyA;

  /// 충돌한 두 번째 물체
  final PhysicsBody bodyB;

  /// 접촉점 (월드 좌표)
  final Vector2D contactPoint;

  /// 충돌 노멀 벡터 (bodyA -> bodyB 방향)
  final Vector2D normal;

  /// 침투 깊이
  final double penetration;

  /// bodyA의 중심에서 접촉점까지의 벡터
  Vector2D rA = Vector2D.zero();

  /// bodyB의 중심에서 접촉점까지의 벡터
  Vector2D rB = Vector2D.zero();

  /// 총 질량 역수 (inverseMassA + inverseMassB)
  double totalInverseMass = 0.0;

  /// 총 관성 모멘트 역수 (회전 효과 관련)
  double totalInverseInertia = 0.0;

  /// 반발계수 (탄성)
  double restitution = 0.2;

  /// 정적 마찰 계수
  double staticFriction = 0.6;

  /// 동적 마찰 계수
  double dynamicFriction = 0.4;

  /// 축적된 노멀 임펄스 (반복 해결에 사용)
  double accumulatedNormalImpulse = 0.0;

  /// 축적된 접선 임펄스 (마찰 해결에 사용)
  double accumulatedTangentImpulse = 0.0;

  /// 접촉이 유지되는지 여부 (다음 프레임에서도 접촉 상태인지)
  bool persistent = false;

  /// 생성자
  ContactManifold({
    required this.bodyA,
    required this.bodyB,
    required this.contactPoint,
    required this.normal,
    required this.penetration,
  });

  /// 접촉 매니폴드 복제
  ContactManifold clone() {
    final manifold = ContactManifold(
      bodyA: bodyA,
      bodyB: bodyB,
      contactPoint: Vector2D.copy(contactPoint),
      normal: Vector2D.copy(normal),
      penetration: penetration,
    );

    manifold.rA = Vector2D.copy(rA);
    manifold.rB = Vector2D.copy(rB);
    manifold.totalInverseMass = totalInverseMass;
    manifold.totalInverseInertia = totalInverseInertia;
    manifold.restitution = restitution;
    manifold.staticFriction = staticFriction;
    manifold.dynamicFriction = dynamicFriction;
    manifold.accumulatedNormalImpulse = accumulatedNormalImpulse;
    manifold.accumulatedTangentImpulse = accumulatedTangentImpulse;
    manifold.persistent = persistent;

    return manifold;
  }

  /// 이 접촉점의 기본 정보 문자열 표현
  @override
  String toString() {
    return 'ContactManifold(point: $contactPoint, normal: $normal, penetration: $penetration)';
  }
}
