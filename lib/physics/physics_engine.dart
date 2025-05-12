import 'dart:math' as math;
import '../models/game/shape.dart';
import 'vector2d.dart';
import 'verlet_integrator.dart';
import 'physics_debug.dart';
import 'physics_body.dart';
import 'collision.dart';

/// 광범위 충돌 검출 방식
enum BroadphaseMethod {
  /// 그리드 기반 방식
  grid,

  /// 쿼드트리 기반 방식
  quadTree,

  /// AABB 트리 기반 방식
  aabbTree,
}

/// 물리 엔진 클래스 - 물리 시뮬레이션의 핵심 로직
class PhysicsEngine {
  /// 중력 가속도
  Vector2D gravity = Vector2D(0, 9.8);

  /// 물리 시뮬레이션 시간 간격 (초)
  double fixedTimeStep = 1 / 60;

  /// 속도 반복 횟수 (충돌 해결의 정확도)
  int velocityIterations = 8;

  /// 위치 반복 횟수 (물체 간 침투 해결)
  int positionIterations = 3;

  /// 서브스텝 수 (복잡한 시뮬레이션을 위한 단계 분할)
  int substeps = 1;

  /// 최대 허용 델타 타임 (초)
  double maxDeltaTime = 1 / 20;

  /// 축적된 시간 (가변 프레임 레이트 처리)
  double _accumulator = 0.0;

  /// 이전 상태에서 다음 상태로의 보간 계수 (0.0-1.0)
  double _alpha = 0.0;

  /// 물리 바디 맵
  final Map<int, PhysicsBody> _bodies = {};

  /// 바디 ID 카운터
  int _nextBodyId = 0;

  /// 휴면 속도 임계값
  double sleepVelocityThreshold = 0.1;

  /// 휴면 각속도 임계값
  double sleepAngularVelocityThreshold = 0.1;

  /// 광범위 충돌 검출을 위한 공간 격자
  final Map<String, GridCell> _grid = {};

  /// 격자 셀 크기
  final double _cellSize = 64.0;

  /// 충돌 이벤트 콜백
  Function(Collision)? onCollision;

  /// Verlet 적분기
  final VerletIntegrator _verletIntegrator = VerletIntegrator();

  /// 물리 디버깅 정보
  final PhysicsDebugInfo debugInfo = PhysicsDebugInfo();

  /// 마지막 업데이트 시간
  double _lastUpdateTime = 0.0;

  /// Verlet 적분 활성화 여부
  bool useVerletIntegration = false;

  /// 디버깅 모드 활성화 여부
  bool debugMode = false;

  /// 광범위 충돌 검출 방식
  BroadphaseMethod broadphaseMethod = BroadphaseMethod.grid;

  /// 정적 물체 캐싱 최적화
  bool useStaticBodyCaching = true;

  /// 캐싱된 정적 물체 쌍
  final Set<String> _cachedStaticPairs = {};

  /// 캐싱된 정적 물체 마지막 업데이트 시간
  final double _lastStaticBodyCacheUpdate = 0.0;

  /// 정적 물체 캐시 업데이트 간격 (프레임)
  int staticBodyCacheUpdateInterval = 10;

  /// 현재 프레임 카운터
  int _frameCounter = 0;

  PhysicsEngine({
    Vector2D? gravity,
    this.fixedTimeStep = 1 / 60,
    this.velocityIterations = 8,
    this.positionIterations = 3,
    this.substeps = 1,
    this.onCollision,
    this.useVerletIntegration = false,
    this.debugMode = false,
    this.broadphaseMethod = BroadphaseMethod.grid,
    this.useStaticBodyCaching = true,
  }) {
    if (gravity != null) {
      this.gravity = gravity;
    }
  }

  /// 보간 계수 가져오기 (렌더링용)
  double get interpolationAlpha => _alpha;

  /// 마지막 단계 이후 경과 시간 (초)
  double get timeSinceLastStep => _accumulator;

  /// 물리 바디 맵에 접근하기 위한 getter (테스트 전용)
  Map<int, PhysicsBody> get bodies => _bodies;

  /// 물리 바디 추가
  int addBody(PhysicsBody body) {
    final id = body.id != -1 ? body.id : _nextBodyId++;

    // ID가 이미 사용 중이면 새 ID 할당
    if (_bodies.containsKey(id)) {
      return addBody(
        PhysicsBody(
          id: -1,
          shape: body.shape,
          type: body.type,
          position: body.position,
          velocity: body.velocity,
          rotation: body.rotation,
          angularVelocity: body.angularVelocity,
          mass: body.mass,
          inertia: body.inertia,
          restitution: body.restitution,
          staticFriction: body.staticFriction,
          dynamicFriction: body.dynamicFriction,
          linearDamping: body.linearDamping,
          angularDamping: body.angularDamping,
          collisionLayer: body.collisionLayer,
          collisionMask: body.collisionMask,
          userData: body.userData,
        ),
      );
    }

    _bodies[id] = body;

    // Verlet 적분기 초기화
    if (useVerletIntegration) {
      _verletIntegrator.initializeState(id, body.position, body.rotation);
    }

    return id;
  }

  /// 물리 바디 가져오기
  PhysicsBody? getBody(int id) {
    return _bodies[id];
  }

  /// 물리 바디 제거
  void removeBody(int id) {
    _bodies.remove(id);

    // Verlet 적분기에서도 제거
    if (useVerletIntegration) {
      _verletIntegrator.removeBody(id);
    }
  }

  /// 모든 물리 바디 제거
  void clearBodies() {
    _bodies.clear();

    // Verlet 적분기 초기화
    if (useVerletIntegration) {
      _verletIntegrator.clear();
    }
  }

  /// 공간 격자에 바디 추가
  void _addBodyToGrid(PhysicsBody body) {
    final aabb = body.aabb;
    final minCellX = (aabb.min.x / _cellSize).floor();
    final minCellY = (aabb.min.y / _cellSize).floor();
    final maxCellX = (aabb.max.x / _cellSize).floor();
    final maxCellY = (aabb.max.y / _cellSize).floor();

    for (int x = minCellX; x <= maxCellX; x++) {
      for (int y = minCellY; y <= maxCellY; y++) {
        final cellKey = '$x,$y';
        if (!_grid.containsKey(cellKey)) {
          _grid[cellKey] = GridCell();
        }
        _grid[cellKey]!.bodies.add(body);
      }
    }
  }

  /// 공간 격자 갱신
  void _updateGrid() {
    _grid.clear();
    for (final body in _bodies.values) {
      _addBodyToGrid(body);
    }
  }

  /// 광범위 충돌 감지 - 가능한 충돌 쌍 찾기
  List<List<PhysicsBody>> _broadphase() {
    if (debugMode) {
      final startTime = DateTime.now().millisecondsSinceEpoch;

      List<List<PhysicsBody>> result;
      switch (broadphaseMethod) {
        case BroadphaseMethod.grid:
          result = _gridBroadphase();
          break;
        case BroadphaseMethod.quadTree:
          result = _quadTreeBroadphase();
          break;
        case BroadphaseMethod.aabbTree:
          result = _aabbTreeBroadphase();
          break;
        default:
          result = _gridBroadphase();
      }

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final elapsedMs = endTime - startTime;

      debugInfo.stats['broadphaseTime'] = elapsedMs.toDouble();
      debugInfo.stats['pairCount'] = result.length.toDouble();

      return result;
    } else {
      switch (broadphaseMethod) {
        case BroadphaseMethod.grid:
          return _gridBroadphase();
        case BroadphaseMethod.quadTree:
          return _quadTreeBroadphase();
        case BroadphaseMethod.aabbTree:
          return _aabbTreeBroadphase();
        default:
          return _gridBroadphase();
      }
    }
  }

  /// 그리드 기반 광범위 충돌 감지
  List<List<PhysicsBody>> _gridBroadphase() {
    _updateGrid();

    final List<List<PhysicsBody>> pairs = [];
    final Set<String> processedPairs = {};

    // 정적 물체 캐시 업데이트
    _frameCounter++;
    if (useStaticBodyCaching &&
        _frameCounter % staticBodyCacheUpdateInterval == 0) {
      _cachedStaticPairs.clear();
    }

    for (final cell in _grid.values) {
      final bodies = cell.bodies;

      // 같은 셀 내의 바디 쌍 처리
      for (int i = 0; i < bodies.length; i++) {
        for (int j = i + 1; j < bodies.length; j++) {
          final bodyA = bodies[i];
          final bodyB = bodies[j];

          // 이미 처리된 쌍인지 확인
          final pairKey =
              '${math.min(bodyA.id, bodyB.id)},${math.max(bodyA.id, bodyB.id)}';
          if (processedPairs.contains(pairKey)) {
            continue;
          }

          // 정적 물체 캐시 확인
          final bothStatic =
              bodyA.type == BodyType.static && bodyB.type == BodyType.static;
          if (useStaticBodyCaching && bothStatic) {
            if (_cachedStaticPairs.contains(pairKey)) {
              // 이전에 충돌하는 정적 물체는 여전히 충돌 중
              pairs.add([bodyA, bodyB]);
              continue;
            } else if (_frameCounter % staticBodyCacheUpdateInterval != 0) {
              // 캐시 업데이트 프레임이 아니면 정적 물체 쌍은 건너뜀
              continue;
            }
          }

          // 충돌 필터링
          if (!bodyA.canCollideWith(bodyB)) {
            continue;
          }

          // AABB 확인
          if (bodyA.aabb.overlaps(bodyB.aabb)) {
            pairs.add([bodyA, bodyB]);
            processedPairs.add(pairKey);

            // 정적 물체 쌍은 캐시에 추가
            if (useStaticBodyCaching && bothStatic) {
              _cachedStaticPairs.add(pairKey);
            }
          }
        }
      }
    }

    return pairs;
  }

  /// 쿼드트리 기반 광범위 충돌 감지
  List<List<PhysicsBody>> _quadTreeBroadphase() {
    // 실제 구현은 quad_tree.dart에 있으며, 여기서는 단순화된 그리드 방식 사용
    return _gridBroadphase();
  }

  /// AABB 트리 기반 광범위 충돌 감지
  List<List<PhysicsBody>> _aabbTreeBroadphase() {
    // 실제 구현은 aabb_tree.dart에 있으며, 여기서는 단순화된 그리드 방식 사용
    return _gridBroadphase();
  }

  /// 정밀 충돌 감지 - 실제 충돌 판정
  List<Collision> _narrowphase(List<List<PhysicsBody>> pairs) {
    final List<Collision> collisions = [];

    for (final pair in pairs) {
      final bodyA = pair[0];
      final bodyB = pair[1];

      // 두 바디 모두 정적이면 무시 (충돌해도 반응 없음)
      if (bodyA.type == BodyType.static && bodyB.type == BodyType.static) {
        continue;
      }

      // Circle vs Circle 충돌 처리
      if (bodyA.shape is Circle && bodyB.shape is Circle) {
        final circleA = bodyA.shape as Circle;
        final circleB = bodyB.shape as Circle;

        // 원 사이의 거리 계산
        final distance = Vector2D.distance(circleA.center, circleB.center);
        final radiusSum = circleA.radius + circleB.radius;

        // 충돌 검사
        if (distance < radiusSum) {
          // 충돌 방향 벡터 (A에서 B로)
          Vector2D normal = Vector2D.zero();
          if (distance > 0) {
            normal = (circleB.center - circleA.center) / distance;
          } else {
            // 중심이 같은 경우 임의 방향
            normal = Vector2D(1, 0);
          }

          // 침투 깊이
          final penetration = radiusSum - distance;

          // 접촉점 계산
          final contactPoint = circleA.center + normal * circleA.radius;

          final collision = Collision(
            bodyA: bodyA,
            bodyB: bodyB,
            normal: normal,
            penetration: penetration,
            contactPoints: [contactPoint],
          );

          collisions.add(collision);

          // 디버깅 모드에서 충돌 정보 저장
          if (debugMode) {
            debugInfo.addCollision(collision);
          }
        }
      }

      // 추가 형태 조합에 대한 충돌 검사는 여기에 추가...
      // Rectangle vs Rectangle, Circle vs Rectangle 등
    }

    return collisions;
  }

  /// 충돌 해결 - 침투 및 속도 처리
  void _solveCollisions(List<Collision> collisions) {
    // 위치 보정
    for (int i = 0; i < positionIterations; i++) {
      for (final collision in collisions) {
        final bodyA = collision.bodyA;
        final bodyB = collision.bodyB;

        // 질량에 기반한 침투 보정 비율
        double totalInverseMass = bodyA.inverseMass + bodyB.inverseMass;
        if (totalInverseMass <= 0) continue;

        double ratio = bodyA.inverseMass / totalInverseMass;
        Vector2D correction =
            collision.normal * collision.penetration * 0.8; // 0.8은 보정 계수

        // 바디 A는 충돌 방향의 반대로 이동
        if (bodyA.type != BodyType.static && bodyA.type != BodyType.kinematic) {
          bodyA.position = bodyA.position - correction * ratio;
        }

        // 바디 B는 충돌 방향으로 이동
        if (bodyB.type != BodyType.static && bodyB.type != BodyType.kinematic) {
          bodyB.position = bodyB.position + correction * (1 - ratio);
        }
      }
    }

    // 속도 해결
    for (int i = 0; i < velocityIterations; i++) {
      for (final collision in collisions) {
        final bodyA = collision.bodyA;
        final bodyB = collision.bodyB;
        final normal = collision.normal;

        // 정적/키네마틱 바디 조합은 처리 최적화
        if ((bodyA.type == BodyType.static ||
                bodyA.type == BodyType.kinematic) &&
            (bodyB.type == BodyType.static ||
                bodyB.type == BodyType.kinematic)) {
          continue;
        }

        // 접촉점에서의 상대 속도 계산
        final contactPoint = collision.contactPoints[0];

        // 각 바디에 대한 접촉점의 상대 위치
        final rA = contactPoint - bodyA.position;
        final rB = contactPoint - bodyB.position;

        // 각 바디의 접촉점에서의 선속도
        final vA =
            bodyA.velocity +
            Vector2D(
              -bodyA.angularVelocity * rA.y,
              bodyA.angularVelocity * rA.x,
            );
        final vB =
            bodyB.velocity +
            Vector2D(
              -bodyB.angularVelocity * rB.y,
              bodyB.angularVelocity * rB.x,
            );

        // 상대 속도
        final relativeVelocity = vB - vA;

        // 접근 속도 (음수면 서로 접근 중)
        final normalVelocity = relativeVelocity.dot(normal);

        // 이미 분리 중이면 처리 불필요
        if (normalVelocity > 0) continue;

        // 반발계수 (두 물체의 반발계수 평균)
        final restitution = (bodyA.restitution + bodyB.restitution) * 0.5;

        // 마찰 계수 (두 물체의 마찰계수 평균)
        final staticFriction = math.sqrt(
          bodyA.staticFriction * bodyB.staticFriction,
        );
        final dynamicFriction = math.sqrt(
          bodyA.dynamicFriction * bodyB.dynamicFriction,
        );

        // 충격량 계산을 위한 분모
        double denominator = bodyA.inverseMass + bodyB.inverseMass;

        // 접촉점에서의 회전 영향 추가
        denominator +=
            bodyA.inverseInertia *
            (rA.dot(rA) - math.pow(rA.dot(normal), 2).toDouble());
        denominator +=
            bodyB.inverseInertia *
            (rB.dot(rB) - math.pow(rB.dot(normal), 2).toDouble());

        if (denominator <= 0) continue;

        // 충격량 크기 계산
        // 노멀 방향으로는 반발 적용, 마찰 방향은 에너지 소실
        double impulse = -(1 + restitution) * normalVelocity / denominator;

        // 충격량 벡터
        final impulseVector = normal * impulse;

        // 바디 A에 충격량 적용
        if (bodyA.type == BodyType.dynamic) {
          bodyA.velocity = bodyA.velocity - impulseVector * bodyA.inverseMass;
          bodyA.angularVelocity -=
              rA.cross(impulseVector) * bodyA.inverseInertia;
        }

        // 바디 B에 충격량 적용
        if (bodyB.type == BodyType.dynamic) {
          bodyB.velocity = bodyB.velocity + impulseVector * bodyB.inverseMass;
          bodyB.angularVelocity +=
              rB.cross(impulseVector) * bodyB.inverseInertia;
        }

        // 마찰력 적용
        final tangent =
            relativeVelocity - normal * relativeVelocity.dot(normal);
        Vector2D tangentNormal = Vector2D.zero();

        if (tangent.magnitudeSquared > 0) {
          tangentNormal = tangent.normalized;
        }

        // 마찰력의 크기
        final frictionImpulse =
            -relativeVelocity.dot(tangentNormal) / denominator;

        // 정적 마찰력과 운동 마찰력 중 적용할 것 결정
        Vector2D frictionVector;
        if (frictionImpulse.abs() < impulse * staticFriction) {
          frictionVector = tangentNormal * frictionImpulse;
        } else {
          frictionVector = tangentNormal * -impulse * dynamicFriction;
        }

        // 바디 A에 마찰력 적용
        if (bodyA.type == BodyType.dynamic) {
          bodyA.velocity = bodyA.velocity - frictionVector * bodyA.inverseMass;
          bodyA.angularVelocity -=
              rA.cross(frictionVector) * bodyA.inverseInertia;
        }

        // 바디 B에 마찰력 적용
        if (bodyB.type == BodyType.dynamic) {
          bodyB.velocity = bodyB.velocity + frictionVector * bodyB.inverseMass;
          bodyB.angularVelocity +=
              rB.cross(frictionVector) * bodyB.inverseInertia;
        }

        // 충돌 이벤트 발생
        if (onCollision != null) {
          onCollision!(collision);
        }
      }
    }
  }

  /// 물리 체계 업데이트 - 외부에서 호출되는 메인 업데이트 함수
  /// @param deltaTime 이전 프레임에서 경과한 시간 (초)
  void update(double deltaTime) {
    if (debugMode) {
      final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final fps =
          _lastUpdateTime > 0 ? 1.0 / (currentTime - _lastUpdateTime) : 0.0;
      debugInfo.addFpsDataPoint(fps);
      debugInfo.stats['deltaTime'] = deltaTime;
      debugInfo.stats['fps'] = fps;
      debugInfo.stats['broadphaseMethod'] = broadphaseMethod.index.toDouble();
      debugInfo.stats['useStaticBodyCaching'] =
          useStaticBodyCaching ? 1.0 : 0.0;
      _lastUpdateTime = currentTime;
    }

    // 최대 델타 타임 제한 (물리 폭주 방지)
    if (deltaTime > maxDeltaTime) {
      deltaTime = maxDeltaTime;
    }

    // 시간 축적기에 델타 타임 추가
    _accumulator += deltaTime;

    // 고정 시간 간격으로 물리 시뮬레이션 실행
    double fixedDt = fixedTimeStep / substeps;
    bool didStep = false;

    while (_accumulator >= fixedDt) {
      for (int i = 0; i < substeps; i++) {
        _step(fixedDt);
      }
      _accumulator -= fixedTimeStep;
      didStep = true;
    }

    // 상태 보간 (렌더링용)
    _alpha = _accumulator / fixedTimeStep;

    // 바디 상태 보간
    if (didStep) {
      for (final body in _bodies.values) {
        body.updateStates();
      }
    }

    // 렌더링용 보간 상태 계산
    for (final body in _bodies.values) {
      body.interpolate(_alpha);

      // 디버깅 모드에서 바디 추적
      if (debugMode && debugInfo.bodyTracking.containsKey(body.id)) {
        debugInfo.recordBodyData(body.id, body);
      }
    }
  }

  /// 단일 고정 시간 간격 스텝 수행
  void _step(double dt) {
    // 1. 모든 바디에 힘 적용 (중력 등)
    _applyForces(dt);

    // 2. 바디 상태 업데이트 (위치, 속도 등)
    _integrate(dt);

    // 3. 광범위 충돌 검출
    final pairs = _broadphase();

    // 4. 정밀 충돌 검출
    final collisions = _narrowphase(pairs);

    // 5. 충돌 해결
    _solveCollisions(collisions);

    // 6. 후처리 (휴면 상태 체크 등)
    _postUpdate();

    if (debugMode) {
      debugInfo.stats['activeBodyCount'] =
          _bodies.values.where((b) => !b.isSleeping).length.toDouble();
      debugInfo.stats['totalBodyCount'] = _bodies.length.toDouble();
      debugInfo.stats['collisionCount'] = collisions.length.toDouble();
    }
  }

  /// 모든 바디에 힘 적용
  void _applyForces(double dt) {
    for (final body in _bodies.values) {
      if (body.type != BodyType.dynamic || body.isSleeping) {
        continue;
      }

      // 중력 적용
      body.applyForce(gravity * body.mass);

      // 추가 힘 적용 가능
    }
  }

  /// 바디 상태 적분 (위치, 속도 업데이트)
  void _integrate(double dt) {
    for (final body in _bodies.values) {
      if (body.type != BodyType.dynamic || body.isSleeping) {
        continue;
      }

      if (useVerletIntegration) {
        // Verlet 적분 사용
        final acceleration = body.force * body.inverseMass;
        final angularAcceleration = body.torque * body.inverseInertia;

        // 위치 및 회전 업데이트
        body.position = _verletIntegrator.integratePosition(
          body.id,
          body.position,
          acceleration,
          dt,
        );
        body.rotation = _verletIntegrator.integrateRotation(
          body.id,
          body.rotation,
          angularAcceleration,
          dt,
        );

        // Verlet 적분기로부터 속도 계산
        body.velocity =
            (body.position - _verletIntegrator.getPreviousPosition(body.id)) /
            dt;
        body.angularVelocity =
            (body.rotation - _verletIntegrator.getPreviousRotation(body.id)) /
            dt;
      } else {
        // 표준 반명시적 오일러 적분 사용
        // 가속도 계산
        final acceleration = body.force * body.inverseMass;

        // 각가속도 계산
        final angularAcceleration = body.torque * body.inverseInertia;

        // 속도 업데이트 (반감쇠 적용)
        body.velocity =
            body.velocity * (1 - body.linearDamping) + acceleration * dt;

        // 각속도 업데이트 (반감쇠 적용)
        body.angularVelocity =
            body.angularVelocity * (1 - body.angularDamping) +
            angularAcceleration * dt;

        // 위치 업데이트
        body.position = body.position + body.velocity * dt;

        // 회전 업데이트
        body.rotation += body.angularVelocity * dt;
      }

      // 힘과 토크 초기화
      body.force = Vector2D.zero();
      body.torque = 0;
    }
  }

  /// 시뮬레이션 후처리
  void _postUpdate() {
    for (final body in _bodies.values) {
      if (body.type != BodyType.dynamic) {
        continue;
      }

      // 휴면 상태 체크
      if (!body.isSleeping) {
        final speedSquared = body.velocity.magnitudeSquared;
        final angularSpeedAbs = body.angularVelocity.abs();

        if (speedSquared < sleepVelocityThreshold * sleepVelocityThreshold &&
            angularSpeedAbs < sleepAngularVelocityThreshold) {
          body.isSleeping = true;
        }
      }
    }
  }

  /// 직접 단일 스텝 실행
  void stepSimulation(double dt) {
    _step(dt);

    // 보간 상태 업데이트
    for (final body in _bodies.values) {
      body.updateStates();
      body.interpolate(0.0); // 보간 없음
    }
  }

  /// 물리 엔진 구성 초기화
  void reset() {
    _accumulator = 0.0;
    _alpha = 0.0;
    _lastUpdateTime = 0.0;

    if (useVerletIntegration) {
      _verletIntegrator.clear();

      // Verlet 적분기 다시 초기화
      for (final body in _bodies.values) {
        _verletIntegrator.initializeState(
          body.id,
          body.position,
          body.rotation,
        );
      }
    }

    // 디버깅 정보 초기화
    if (debugMode) {
      debugInfo.clear();
    }
  }
}
