import 'dart:math' as math;
import 'vector2d.dart';
import 'physics_body.dart';
import 'collision.dart';
import 'contact_manifold.dart';

/// 충격 기반 충돌 응답 해결을 위한 솔버 클래스
class ImpulseSolver {
  /// 위치 보정 계수 (0.0 ~ 1.0)
  double positionalCorrectionFactor = 0.8;

  /// 위치 보정 허용치
  double allowedPenetration = 0.01;

  /// 반복 횟수 - 충돌 해결의 정확도
  int iterations;

  /// 비정상 값을 감지하고 대체하기 위한 임계값
  static const double LARGE_VALUE = 100000.0;

  /// 생성자
  ImpulseSolver({this.iterations = 10});

  /// 모든 충돌 해결
  void solve(List<Collision> collisions, double dt) {
    // 충돌당 여러 접촉점을 가질 수 있으므로 먼저 충돌 매니폴드로 변환
    final List<ContactManifold> manifolds = _createManifolds(collisions);

    // 위치 보정
    _correctPositions(manifolds);

    // 속도 해결
    _solveVelocities(manifolds, dt);
  }

  /// 충돌을 접촉 매니폴드로 변환
  List<ContactManifold> _createManifolds(List<Collision> collisions) {
    final List<ContactManifold> manifolds = [];

    for (final collision in collisions) {
      final bodyA = collision.bodyA;
      final bodyB = collision.bodyB;
      final normal = collision.normal;

      // 각 접촉점에 대한 매니폴드 생성
      for (final contactPoint in collision.contactPoints) {
        final manifold = ContactManifold(
          bodyA: bodyA,
          bodyB: bodyB,
          contactPoint: contactPoint,
          normal: normal,
          penetration: collision.penetration,
        );

        // 매니폴드 전처리
        _preprocessManifold(manifold);

        manifolds.add(manifold);
      }
    }

    return manifolds;
  }

  /// 매니폴드 전처리 - 접촉점에서의 상대 위치 및 질량 계산
  void _preprocessManifold(ContactManifold manifold) {
    final bodyA = manifold.bodyA;
    final bodyB = manifold.bodyB;
    final contactPoint = manifold.contactPoint;

    // 각 바디에 대한 접촉점의 상대 위치
    manifold.rA = contactPoint - bodyA.position;
    manifold.rB = contactPoint - bodyB.position;

    // 질량 역수 합
    manifold.totalInverseMass = bodyA.inverseMass + bodyB.inverseMass;

    // 각 모멘텀 역수 합
    manifold.totalInverseInertia = _calculateInverseInertiaSum(manifold);

    // 반발 계수 계산
    manifold.restitution = math.min(bodyA.restitution, bodyB.restitution);

    // 마찰 계수 계산
    manifold.staticFriction = math.sqrt(
      bodyA.staticFriction * bodyB.staticFriction,
    );
    manifold.dynamicFriction = math.sqrt(
      bodyA.dynamicFriction * bodyB.dynamicFriction,
    );
  }

  /// 접촉 매니폴드에 대한 角운동량 역수 합 계산
  double _calculateInverseInertiaSum(ContactManifold manifold) {
    final bodyA = manifold.bodyA;
    final bodyB = manifold.bodyB;
    final rA = manifold.rA;
    final rB = manifold.rB;
    final normal = manifold.normal;

    double result = 0.0;

    // Cross product squared terms for rotational effects
    if (bodyA.type == BodyType.dynamic) {
      final crossA = rA.cross(normal);
      result += bodyA.inverseInertia * crossA * crossA;
    }

    if (bodyB.type == BodyType.dynamic) {
      final crossB = rB.cross(normal);
      result += bodyB.inverseInertia * crossB * crossB;
    }

    return result;
  }

  /// 위치 오차 보정 - 침투 현상 해결
  void _correctPositions(List<ContactManifold> manifolds) {
    for (final manifold in manifolds) {
      final bodyA = manifold.bodyA;
      final bodyB = manifold.bodyB;

      // 두 바디 모두 움직일 수 없으면 건너뜀
      if ((bodyA.type != BodyType.dynamic && bodyB.type != BodyType.dynamic) ||
          manifold.totalInverseMass <= 0) {
        continue;
      }

      // 허용 침투 이하면 보정하지 않음 (성능 최적화)
      if (manifold.penetration <= allowedPenetration) {
        continue;
      }

      // 침투 보정량 계산
      final correction =
          manifold.normal *
          (manifold.penetration - allowedPenetration) *
          positionalCorrectionFactor /
          manifold.totalInverseMass;

      // 각 바디의 질량에 비례하여 보정량 적용
      if (bodyA.type == BodyType.dynamic) {
        final moveA = correction * bodyA.inverseMass;
        bodyA.position = bodyA.position - moveA;
      }

      if (bodyB.type == BodyType.dynamic) {
        final moveB = correction * bodyB.inverseMass;
        bodyB.position = bodyB.position + moveB;
      }
    }
  }

  /// 속도 해결 - 충격량 적용
  void _solveVelocities(List<ContactManifold> manifolds, double dt) {
    // 임계 속도 (Threshold velocity) - 이 값 이하의 속도는 0으로 간주
    const double velocityThreshold = 0.01;

    for (int iteration = 0; iteration < iterations; iteration++) {
      for (final manifold in manifolds) {
        final bodyA = manifold.bodyA;
        final bodyB = manifold.bodyB;
        final normal = manifold.normal;
        final rA = manifold.rA;
        final rB = manifold.rB;

        // 두 바디 모두 움직일 수 없으면 건너뜀
        if ((bodyA.type != BodyType.dynamic &&
                bodyB.type != BodyType.dynamic) ||
            manifold.totalInverseMass <= 0) {
          continue;
        }

        // 각 바디의 접촉점에서의 선속도
        final vA = bodyA.getVelocityAtPoint(rA);
        final vB = bodyB.getVelocityAtPoint(rB);

        // 상대 속도
        final relativeVelocity = vB - vA;

        // 노멀 방향 속도 (접근 속도)
        final normalVelocity = relativeVelocity.dot(normal);

        // 이미 분리 중이면 반발력 계산 생략
        if (normalVelocity > 0) {
          continue;
        }

        // 충격량 계산을 위한 분모
        double inverseMassSum =
            manifold.totalInverseMass + manifold.totalInverseInertia;
        if (inverseMassSum < 0.00001) continue;

        // 충격량 계산
        double j =
            -(1.0 + manifold.restitution) * normalVelocity / inverseMassSum;

        // 비정상적으로 큰 충격량 방지
        if (j.abs() > LARGE_VALUE) {
          j = j.sign * LARGE_VALUE;
        }

        // 노멀 방향 충격량 벡터
        final impulse = normal * j;

        // 각 바디에 충격량 적용
        _applyImpulse(bodyA, -impulse, rA);
        _applyImpulse(bodyB, impulse, rB);

        // ---- 마찰력 계산 ----
        // 마찰 방향 벡터 계산 (상대 속도에서 노멀 성분 제거)
        final tangent = _calculateTangent(relativeVelocity, normal);

        // 마찰 방향 속도
        final tangentVelocity = relativeVelocity.dot(tangent);

        // 마찰력 계산
        double jt = -tangentVelocity / inverseMassSum;

        // 마찰 충격량을 노멀 충격량 기준으로 제한 (Coulomb's Law)
        double maxFriction = j * manifold.staticFriction;

        // 정적 마찰력과 동적 마찰력 중 적절한 것 선택
        if (jt.abs() < maxFriction) {
          // 정적 마찰력 (완전히 상대 속도 제거)
        } else {
          // 동적 마찰력 (일정 비율로 감소)
          jt = -j * manifold.dynamicFriction * jt.sign;
        }

        // 비정상적으로 큰 마찰력 방지
        if (jt.abs() > LARGE_VALUE) {
          jt = jt.sign * LARGE_VALUE;
        }

        // 마찰 충격량 벡터
        final frictionImpulse = tangent * jt;

        // 각 바디에 마찰 충격량 적용
        _applyImpulse(bodyA, -frictionImpulse, rA);
        _applyImpulse(bodyB, frictionImpulse, rB);
      }
    }

    // 매우 작은 속도는 0으로 설정하여 안정화
    for (final manifold in manifolds) {
      _stabilizeBody(manifold.bodyA, velocityThreshold);
      _stabilizeBody(manifold.bodyB, velocityThreshold);
    }
  }

  /// 물체에 충격량 적용
  void _applyImpulse(PhysicsBody body, Vector2D impulse, Vector2D r) {
    if (body.type != BodyType.dynamic) return;

    // 선형 충격량 적용
    body.velocity = body.velocity + impulse * body.inverseMass;

    // 각 충격량 적용
    body.angularVelocity += r.cross(impulse) * body.inverseInertia;
  }

  /// 마찰 방향 벡터 계산
  Vector2D _calculateTangent(Vector2D relativeVelocity, Vector2D normal) {
    // 노멀 성분 제거
    Vector2D tangentVelocity =
        relativeVelocity - normal * relativeVelocity.dot(normal);

    // 매우 작은 속도는 일반화하지 않음
    if (tangentVelocity.magnitudeSquared < 0.0001) {
      // 수직 벡터 생성
      return Vector2D(-normal.y, normal.x);
    }

    // 정규화된 마찰 방향 반환
    return tangentVelocity.normalized;
  }

  /// 물체 안정화 - 매우 작은 속도는 0으로 설정
  void _stabilizeBody(PhysicsBody body, double threshold) {
    if (body.type != BodyType.dynamic) return;

    // 매우 작은 선형 속도는 0으로
    if (body.velocity.magnitudeSquared < threshold * threshold) {
      body.velocity = Vector2D.zero();
    }

    // 매우 작은 각속도는 0으로
    if (body.angularVelocity.abs() < threshold) {
      body.angularVelocity = 0.0;
    }
  }
}
