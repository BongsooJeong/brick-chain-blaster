import 'dart:math' as math;
import '../models/game/shape.dart';
import 'vector2d.dart';
import 'collision.dart';
import 'physics_body.dart';

/// 정밀 충돌 검출 알고리즘들을 포함하는 유틸리티 클래스
class CollisionDetection {
  /// GJK(Gilbert-Johnson-Keerthi) 알고리즘을 통한 두 볼록 다각형의 충돌 검사
  /// @return 충돌이 발생했는지 여부와 최소 침투 벡터(MTV)를 포함하는 [GJKResult]
  static GJKResult gjk(List<Vector2D> verticesA, List<Vector2D> verticesB) {
    // 초기 방향 (x축 방향으로 시작)
    Vector2D direction = Vector2D(1, 0);

    // 심플렉스(simplex) 구성 (최대 3개의 점)
    final List<Vector2D> simplex = [];

    // 첫 번째 지원점 찾기
    final firstPoint = _support(verticesA, verticesB, direction);
    simplex.add(firstPoint);

    // 다음 방향은 원점을 향하도록 설정
    direction = Vector2D.zero() - firstPoint;

    // GJK 반복 (최대 100회)
    for (int i = 0; i < 100; i++) {
      // 새로운 지원점 찾기
      final support = _support(verticesA, verticesB, direction);

      // 원점 방향으로의 진전이 없으면 충돌 없음
      if (support.dot(direction) < 0) {
        return GJKResult(collides: false);
      }

      // 심플렉스에 점 추가
      simplex.add(support);

      // 원점이 심플렉스에 포함되는지 확인하고 다음 방향 설정
      if (_processSimplex(simplex, direction)) {
        // EPA 알고리즘으로 침투 깊이와 방향 계산
        return _epa(verticesA, verticesB, simplex);
      }
    }

    // 최대 반복 횟수 초과 - 안전을 위해 충돌 없음으로 판정
    return GJKResult(collides: false);
  }

  /// 지원 함수 (Support Function) - 주어진 방향으로 가장 멀리 있는 미코브스키 차이의 점 찾기
  static Vector2D _support(
    List<Vector2D> verticesA,
    List<Vector2D> verticesB,
    Vector2D direction,
  ) {
    // A에서 방향으로 가장 멀리 있는 점
    Vector2D furthestA = _getFurthestPoint(verticesA, direction);

    // B에서 반대 방향으로 가장 멀리 있는 점
    Vector2D furthestB = _getFurthestPoint(verticesB, direction * -1);

    // 미코브스키 차이 점 반환
    return furthestA - furthestB;
  }

  /// 주어진 방향으로 가장 멀리 있는 점 찾기
  static Vector2D _getFurthestPoint(
    List<Vector2D> vertices,
    Vector2D direction,
  ) {
    Vector2D furthest = vertices[0];
    double maxDot = vertices[0].dot(direction);

    for (int i = 1; i < vertices.length; i++) {
      final dot = vertices[i].dot(direction);
      if (dot > maxDot) {
        maxDot = dot;
        furthest = vertices[i];
      }
    }

    return furthest;
  }

  /// 심플렉스 처리 및 다음 방향 설정
  /// @return 원점이 심플렉스에 포함되면 true
  static bool _processSimplex(List<Vector2D> simplex, Vector2D direction) {
    if (simplex.length == 2) {
      // 선분 케이스
      return _processLineSimplex(simplex, direction);
    } else if (simplex.length == 3) {
      // 삼각형 케이스
      return _processTriangleSimplex(simplex, direction);
    }

    return false;
  }

  /// 선분 심플렉스 처리
  static bool _processLineSimplex(List<Vector2D> simplex, Vector2D direction) {
    final b = simplex[0]; // 첫 번째 점
    final a = simplex[1]; // 가장 최근에 추가된 점

    // ab 벡터와 원점에서 b까지의 벡터
    final ab = b - a;
    final ao = Vector2D.zero() - a;

    // 세 번째 점을 구하는 방향 계산 (ao에 수직인 ab의 원점 측면)
    direction.x = ab.y;
    direction.y = -ab.x;

    // 원점 방향이 맞는지 확인, 아니면 반대 방향
    if (direction.dot(ao) < 0) {
      direction.x = -direction.x;
      direction.y = -direction.y;
    }

    return false; // 선분은 항상 원점을 포함할 수 없음
  }

  /// 삼각형 심플렉스 처리
  static bool _processTriangleSimplex(
    List<Vector2D> simplex,
    Vector2D direction,
  ) {
    final c = simplex[0]; // 첫 번째 점
    final b = simplex[1]; // 두 번째 점
    final a = simplex[2]; // 가장 최근에 추가된 점

    final ab = b - a;
    final ac = c - a;
    final ao = Vector2D.zero() - a;

    // 삼각형 법선 (외적)
    final double abcCross = ab.cross(ac);
    final Vector2D abc = Vector2D(0, abcCross > 0 ? 1 : -1);

    // 원점이 삼각형의 AC 모서리 부근인지 확인
    final acPerp = Vector2D(ac.y, -ac.x); // ac에 수직인 벡터
    final acNormal = acPerp * (abc.y > 0 ? 1 : -1); // 외적 방향에 따라 조정

    if (acNormal.dot(ao) > 0) {
      // 원점이 AC 측면에 있음
      simplex.removeAt(1); // b 제거
      direction.x = acNormal.x;
      direction.y = acNormal.y;
      return false;
    }

    // 원점이 삼각형의 AB 모서리 부근인지 확인
    final abPerp = Vector2D(-ab.y, ab.x); // ab에 수직인 벡터
    final abNormal = abPerp * (abc.y > 0 ? 1 : -1); // 외적 방향에 따라 조정

    if (abNormal.dot(ao) > 0) {
      // 원점이 AB 측면에 있음
      simplex.removeAt(0); // c 제거
      direction.x = abNormal.x;
      direction.y = abNormal.y;
      return false;
    }

    // 원점이 삼각형 내부에 있음
    return true;
  }

  /// EPA(Expanding Polytope Algorithm) - 침투 깊이와 방향 계산
  static GJKResult _epa(
    List<Vector2D> verticesA,
    List<Vector2D> verticesB,
    List<Vector2D> simplex,
  ) {
    // 미코브스키 차이의 경계 다각형으로 시작
    final List<Vector2D> polytope = List.from(simplex);

    // EPA의 최대 반복 횟수
    const int maxIterations = 20;

    // 초기 최소 거리와 방향 설정
    double minDistance = double.infinity;
    Vector2D minNormal = Vector2D.zero();

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      // 원점에 가장 가까운 모서리 찾기
      int closestEdgeIndex = -1;
      double closestDistance = double.infinity;
      Vector2D closestNormal = Vector2D.zero();

      for (int i = 0; i < polytope.length; i++) {
        final a = polytope[i];
        final b = polytope[(i + 1) % polytope.length];

        // 모서리 벡터
        final edge = b - a;

        // 원점에서 모서리로의 수직 법선
        final normal = Vector2D(edge.y, -edge.x).normalized;

        // 원점에서 모서리까지의 거리
        final distance = normal.dot(a);

        if (distance < closestDistance) {
          closestDistance = distance;
          closestEdgeIndex = i;
          closestNormal = normal;
        }
      }

      // 새 지원점 찾기
      final support = _support(verticesA, verticesB, closestNormal);

      // 지원점이 현재 다각형을 확장하는지 확인
      final supportDistance = closestNormal.dot(support);

      // 정밀도 허용 오차 (수치 안정성을 위해)
      const double EPSILON = 0.0001;

      if (supportDistance - closestDistance < EPSILON) {
        // 확장이 더 이상 없음 - 최소 침투 벡터 찾음
        minDistance = closestDistance;
        minNormal = closestNormal;
        break;
      }

      // 다각형에 새 지원점 추가
      polytope.insert(closestEdgeIndex + 1, support);
    }

    return GJKResult(
      collides: true,
      normal: minNormal * -1, // 침투 방향 (A에서 B로)
      depth: minDistance,
    );
  }

  /// SAT(Separating Axis Theorem)을 사용한 다각형 간 충돌 검사
  static SATResult satPolygons(Polygon polyA, Polygon polyB) {
    // 다각형의 모든 모서리에서 법선 벡터 추출
    List<Vector2D> normalsA = _getPolygonNormals(polyA.vertices);
    List<Vector2D> normalsB = _getPolygonNormals(polyB.vertices);

    double smallestOverlap = double.infinity;
    Vector2D smallestAxis = Vector2D.zero();
    bool fromA = true;

    // 다각형 A의 모든 모서리에 대한 법선 축 검사
    for (final normal in normalsA) {
      // A와 B의 모든 정점을 각 축에 투영
      ProjectionResult projA = _projectPolygon(polyA.vertices, normal);
      ProjectionResult projB = _projectPolygon(polyB.vertices, normal);

      // 투영이 겹치지 않으면 분리축이 존재하므로 충돌 없음
      if (projA.max < projB.min || projB.max < projA.min) {
        return SATResult(collides: false);
      }

      // 겹침 계산
      double overlap =
          math.min(projA.max, projB.max) - math.max(projA.min, projB.min);

      // 가장 작은 겹침 기록 (침투 깊이가 가장 작은 축이 MTV)
      if (overlap < smallestOverlap) {
        smallestOverlap = overlap;
        smallestAxis = normal;

        // A의 최대값이 B의 최대값보다 크면 방향 반전 필요
        if (projA.max > projB.max) {
          smallestAxis = smallestAxis * -1;
        }
      }
    }

    // 다각형 B의 모든 모서리에 대한 법선 축 검사
    for (final normal in normalsB) {
      ProjectionResult projA = _projectPolygon(polyA.vertices, normal);
      ProjectionResult projB = _projectPolygon(polyB.vertices, normal);

      if (projA.max < projB.min || projB.max < projA.min) {
        return SATResult(collides: false);
      }

      double overlap =
          math.min(projA.max, projB.max) - math.max(projA.min, projB.min);

      if (overlap < smallestOverlap) {
        smallestOverlap = overlap;
        smallestAxis = normal;
        fromA = false;

        // A의 최대값이 B의 최대값보다 크면 방향 반전 필요
        if (projA.max > projB.max) {
          smallestAxis = smallestAxis * -1;
        }
      }
    }

    // 충돌 발생, 최소 이동 벡터 반환
    return SATResult(
      collides: true,
      normal: smallestAxis,
      depth: smallestOverlap,
      fromA: fromA,
    );
  }

  /// 다각형의 모서리에서 법선 벡터 추출
  static List<Vector2D> _getPolygonNormals(List<Vector2D> vertices) {
    List<Vector2D> normals = [];

    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      final edge = next - current;

      // 모서리에 수직인 법선 벡터 (시계 방향으로 90도 회전)
      normals.add(Vector2D(-edge.y, edge.x).normalized);
    }

    return normals;
  }

  /// 다각형의 모든 정점을 주어진 축에 투영
  static ProjectionResult _projectPolygon(
    List<Vector2D> vertices,
    Vector2D axis,
  ) {
    double min = double.infinity;
    double max = double.negativeInfinity;

    for (final vertex in vertices) {
      final projection = vertex.dot(axis);

      if (projection < min) min = projection;
      if (projection > max) max = projection;
    }

    return ProjectionResult(min: min, max: max);
  }

  /// AABB vs AABB 충돌 검사 (최적화된 버전)
  static AABBCollisionResult aabbVsAabb(AABB a, AABB b) {
    // 겹침 여부 확인
    if (a.max.x < b.min.x ||
        a.min.x > b.max.x ||
        a.max.y < b.min.y ||
        a.min.y > b.max.y) {
      return AABBCollisionResult(collides: false);
    }

    // x축과 y축의 겹침 계산
    double overlapX = math.min(a.max.x, b.max.x) - math.max(a.min.x, b.min.x);
    double overlapY = math.min(a.max.y, b.max.y) - math.max(a.min.y, b.min.y);

    // 더 작은 겹침 사용 (최소 이동 벡터)
    Vector2D normal;
    double depth;

    if (overlapX < overlapY) {
      depth = overlapX;
      normal = Vector2D(1, 0);

      // 중심점 기준으로 방향 결정
      if (a.center.x > b.center.x) {
        normal = normal * -1;
      }
    } else {
      depth = overlapY;
      normal = Vector2D(0, 1);

      if (a.center.y > b.center.y) {
        normal = normal * -1;
      }
    }

    return AABBCollisionResult(collides: true, normal: normal, depth: depth);
  }

  /// 원 vs 원 충돌 검사
  static CircleCollisionResult circleVsCircle(Circle a, Circle b) {
    final distance = Vector2D.distance(a.center, b.center);
    final radiusSum = a.radius + b.radius;

    if (distance >= radiusSum) {
      return CircleCollisionResult(collides: false);
    }

    // 충돌 방향 (A에서 B로)
    Vector2D normal;
    if (distance > 0) {
      normal = (b.center - a.center) / distance;
    } else {
      // 중심이 일치하면 임의 방향 사용
      normal = Vector2D(1, 0);
    }

    // 접촉점 계산
    final contactPoint = a.center + normal * a.radius;

    return CircleCollisionResult(
      collides: true,
      normal: normal,
      depth: radiusSum - distance,
      contactPoint: contactPoint,
    );
  }

  /// 원 vs AABB 충돌 검사
  static CircleAABBCollisionResult circleVsAabb(Circle circle, AABB aabb) {
    // AABB에 가장 가까운 원의 점 찾기
    final closestPoint = Vector2D(
      _clamp(circle.center.x, aabb.min.x, aabb.max.x),
      _clamp(circle.center.y, aabb.min.y, aabb.max.y),
    );

    // 원의 중심에서 가장 가까운 점까지의 거리 계산
    final distance = Vector2D.distance(circle.center, closestPoint);

    if (distance > circle.radius) {
      return CircleAABBCollisionResult(collides: false);
    }

    // 충돌 방향
    Vector2D normal;
    if (distance > 0) {
      normal = (closestPoint - circle.center) / distance * -1;
    } else {
      // 원이 AABB 내부에 있는 경우, 가장 가까운 면으로 방향 설정
      final center = aabb.center;
      final halfSize = (aabb.max - aabb.min) * 0.5;

      final distToLeft = (circle.center.x - (center.x - halfSize.x)).abs();
      final distToRight = (circle.center.x - (center.x + halfSize.x)).abs();
      final distToTop = (circle.center.y - (center.y - halfSize.y)).abs();
      final distToBottom = (circle.center.y - (center.y + halfSize.y)).abs();

      // 가장 가까운 면 찾기
      double minDist = math.min(
        math.min(distToLeft, distToRight),
        math.min(distToTop, distToBottom),
      );

      if (minDist == distToLeft) {
        normal = Vector2D(-1, 0);
      } else if (minDist == distToRight) {
        normal = Vector2D(1, 0);
      } else if (minDist == distToTop) {
        normal = Vector2D(0, -1);
      } else {
        normal = Vector2D(0, 1);
      }
    }

    return CircleAABBCollisionResult(
      collides: true,
      normal: normal,
      depth: circle.radius - distance,
      contactPoint: closestPoint,
    );
  }

  /// 값을 지정된 범위로 제한
  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// 연속 충돌 감지 (CCD) - 빠르게 이동하는 물체용
  static CCDResult sweepTest(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    double deltaTime,
  ) {
    if (bodyA.shape is Circle && bodyB.shape is Circle) {
      return _sweepCircleVsCircle(
        bodyA.shape as Circle,
        bodyB.shape as Circle,
        bodyA.position,
        bodyB.position,
        bodyA.velocity,
        bodyB.velocity,
        deltaTime,
      );
    }

    // 다른 형태 조합에 대한 CCD 구현 필요...

    return CCDResult(collision: false);
  }

  /// 원 vs 원 연속 충돌 감지
  static CCDResult _sweepCircleVsCircle(
    Circle circleA,
    Circle circleB,
    Vector2D posA,
    Vector2D posB,
    Vector2D velA,
    Vector2D velB,
    double deltaTime,
  ) {
    // 상대 속도
    final relativeVel = velB - velA;

    // 시작 위치
    final startPosA = posA;
    final startPosB = posB;

    // 시작 시 충돌 여부 확인
    final startDist = Vector2D.distance(startPosA, startPosB);
    final radiusSum = circleA.radius + circleB.radius;

    if (startDist <= radiusSum) {
      // 이미 충돌 중
      return CCDResult(
        collision: true,
        time: 0,
        point: startPosA + (startPosB - startPosA).normalized * circleA.radius,
        normal: (startPosB - startPosA) / startDist,
      );
    }

    // 이차방정식 계수 계산
    final a = relativeVel.dot(relativeVel);
    if (a < 0.001) {
      // 상대 속도가 너무 작음
      return CCDResult(collision: false);
    }

    final startPosDiff = startPosA - startPosB;
    final b = 2 * relativeVel.dot(startPosDiff);
    final c = startPosDiff.dot(startPosDiff) - radiusSum * radiusSum;

    // 판별식
    final discriminant = b * b - 4 * a * c;

    if (discriminant < 0) {
      // 해가 없음 (충돌 없음)
      return CCDResult(collision: false);
    }

    // 충돌 시간 계산
    final time = (-b - math.sqrt(discriminant)) / (2 * a);

    if (time < 0 || time > deltaTime) {
      // 과거 또는 미래 프레임의 충돌
      return CCDResult(collision: false);
    }

    // 충돌 시 위치 계산
    final collisionPosA = startPosA + velA * time;
    final collisionPosB = startPosB + velB * time;

    // 충돌 법선 및 접촉점
    final normal = (collisionPosB - collisionPosA).normalized;
    final point = collisionPosA + normal * circleA.radius;

    return CCDResult(collision: true, time: time, point: point, normal: normal);
  }
}

/// GJK 알고리즘 결과
class GJKResult {
  final bool collides;
  final Vector2D normal;
  final double depth;

  GJKResult({required this.collides, Vector2D? normal, double? depth})
    : normal = normal ?? Vector2D.zero(),
      depth = depth ?? 0;
}

/// SAT 알고리즘 결과
class SATResult {
  final bool collides;
  final Vector2D normal;
  final double depth;
  final bool fromA;

  SATResult({
    required this.collides,
    Vector2D? normal,
    double? depth,
    bool? fromA,
  }) : normal = normal ?? Vector2D.zero(),
       depth = depth ?? 0,
       fromA = fromA ?? true;
}

/// 다각형 투영 결과
class ProjectionResult {
  final double min;
  final double max;

  ProjectionResult({required this.min, required this.max});
}

/// AABB 충돌 결과
class AABBCollisionResult {
  final bool collides;
  final Vector2D normal;
  final double depth;

  AABBCollisionResult({required this.collides, Vector2D? normal, double? depth})
    : normal = normal ?? Vector2D.zero(),
      depth = depth ?? 0;
}

/// 원 충돌 결과
class CircleCollisionResult {
  final bool collides;
  final Vector2D normal;
  final double depth;
  final Vector2D contactPoint;

  CircleCollisionResult({
    required this.collides,
    Vector2D? normal,
    double? depth,
    Vector2D? contactPoint,
  }) : normal = normal ?? Vector2D.zero(),
       depth = depth ?? 0,
       contactPoint = contactPoint ?? Vector2D.zero();
}

/// 원-AABB 충돌 결과
class CircleAABBCollisionResult {
  final bool collides;
  final Vector2D normal;
  final double depth;
  final Vector2D contactPoint;

  CircleAABBCollisionResult({
    required this.collides,
    Vector2D? normal,
    double? depth,
    Vector2D? contactPoint,
  }) : normal = normal ?? Vector2D.zero(),
       depth = depth ?? 0,
       contactPoint = contactPoint ?? Vector2D.zero();
}

/// CCD(연속 충돌 감지) 결과
class CCDResult {
  final bool collision;
  final double time;
  final Vector2D point;
  final Vector2D normal;

  CCDResult({
    required this.collision,
    double? time,
    Vector2D? point,
    Vector2D? normal,
  }) : time = time ?? 0,
       point = point ?? Vector2D.zero(),
       normal = normal ?? Vector2D.zero();
}
