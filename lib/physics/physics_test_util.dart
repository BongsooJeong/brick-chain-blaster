import 'dart:math' as math;
import 'vector2d.dart';
import 'physics_engine.dart';
import '../models/game/shape.dart';

/// 물리 엔진 테스트 유틸리티
/// 다양한 프레임 레이트에서 물리 엔진의 동작을 테스트하기 위한 도구 모음
class PhysicsTestUtil {
  /// 물리 엔진 인스턴스
  final PhysicsEngine engine;

  /// 무작위 숫자 생성기
  final math.Random _random;

  /// 현재 시뮬레이션 시간
  double _simulationTime = 0.0;

  /// 시뮬레이션 객체 ID 목록
  final List<int> _objectIds = [];

  /// 생성자
  PhysicsTestUtil(this.engine, {int? seed}) : _random = math.Random(seed);

  /// 무작위 테스트 장면 생성
  List<int> createRandomScene({
    int objectCount = 10,
    double minSize = 10.0,
    double maxSize = 30.0,
    double arenaWidth = 800.0,
    double arenaHeight = 600.0,
    double initialVelocityMax = 100.0,
  }) {
    _objectIds.clear();

    // 경계 벽 생성
    _createBoundaryWalls(arenaWidth, arenaHeight);

    // 무작위 물체 생성
    for (int i = 0; i < objectCount; i++) {
      final size = minSize + _random.nextDouble() * (maxSize - minSize);
      final x = size + _random.nextDouble() * (arenaWidth - size * 2);
      final y = size + _random.nextDouble() * (arenaHeight - size * 2);

      final velocity = Vector2D(
        (_random.nextDouble() * 2 - 1) * initialVelocityMax,
        (_random.nextDouble() * 2 - 1) * initialVelocityMax,
      );

      // 50% 확률로 원형 또는 사각형 생성
      final shape =
          _random.nextBool()
              ? Circle(center: Vector2D(0, 0), radius: size)
              : Rectangle(
                center: Vector2D(0, 0),
                width: size * 2,
                height: size * 2,
              );

      final body = PhysicsBody(
        id: -1,
        shape: shape,
        position: Vector2D(x, y),
        velocity: velocity,
        rotation: _random.nextDouble() * math.pi * 2,
        angularVelocity: (_random.nextDouble() * 2 - 1) * 2.0,
        mass: size * size * 0.1,
        restitution: 0.7 + _random.nextDouble() * 0.3,
        staticFriction: 0.1 + _random.nextDouble() * 0.1,
        dynamicFriction: 0.05 + _random.nextDouble() * 0.1,
      );

      final id = engine.addBody(body);
      _objectIds.add(id);
    }

    return List.from(_objectIds);
  }

  /// 경계 벽 생성
  void _createBoundaryWalls(double width, double height) {
    // 하단 벽
    final bottomWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(center: Vector2D(0, 0), width: width, height: 20),
      position: Vector2D(width / 2, height + 10),
      mass: 0,
      restitution: 0.8,
      collisionLayer: CollisionLayer.WALL,
    );

    // 상단 벽
    final topWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(center: Vector2D(0, 0), width: width, height: 20),
      position: Vector2D(width / 2, -10),
      mass: 0,
      restitution: 0.8,
      collisionLayer: CollisionLayer.WALL,
    );

    // 좌측 벽
    final leftWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(center: Vector2D(0, 0), width: 20, height: height),
      position: Vector2D(-10, height / 2),
      mass: 0,
      restitution: 0.8,
      collisionLayer: CollisionLayer.WALL,
    );

    // 우측 벽
    final rightWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(center: Vector2D(0, 0), width: 20, height: height),
      position: Vector2D(width + 10, height / 2),
      mass: 0,
      restitution: 0.8,
      collisionLayer: CollisionLayer.WALL,
    );

    engine.addBody(bottomWall);
    engine.addBody(topWall);
    engine.addBody(leftWall);
    engine.addBody(rightWall);
  }

  /// 미리 정의된 테스트 케이스를 실행하고 결과 비교
  /// 다양한
  /// 프레임 레이트에서도 동일한 결과가 나오는지 확인
  Map<String, dynamic> runFrameRateTest({
    required List<double> frameRates,
    required double duration,
    int? objectCount,
  }) {
    // 결과 저장 맵
    final results = <String, dynamic>{};

    // 최초 테스트를 위한 장면 생성 (객체 위치/속도 동일하게)
    final seed = DateTime.now().millisecondsSinceEpoch;
    final baselineEngine = PhysicsEngine(
      gravity: engine.gravity,
      fixedTimeStep: 1 / 60,
      velocityIterations: engine.velocityIterations,
      positionIterations: engine.positionIterations,
      substeps: engine.substeps,
      useVerletIntegration: engine.useVerletIntegration,
    );

    final baselineUtil = PhysicsTestUtil(baselineEngine, seed: seed);
    final baselineIds =
        objectCount != null
            ? baselineUtil.createRandomScene(objectCount: objectCount)
            : baselineUtil.createRandomScene();

    // 기준 결과 생성 (60 FPS에서 정확한 타임스텝으로 시뮬레이션)
    final exactBaselineResult = _runExactStepSimulation(
      baselineEngine,
      duration: duration,
      stepSize: 1 / 60,
    );
    results['baseline'] = exactBaselineResult;

    // 다양한 프레임 레이트에서 시뮬레이션 실행 및 결과 비교
    for (final fps in frameRates) {
      // 엔진 초기화
      engine.clearBodies();
      _objectIds.clear();
      _simulationTime = 0.0;

      // 동일한 초기 상태 재생성
      final util = PhysicsTestUtil(engine, seed: seed);
      util.createRandomScene(objectCount: objectCount ?? 10);

      // 시뮬레이션 실행
      final testResult = _runVariableFrameRateSimulation(
        duration: duration,
        targetFrameRate: fps,
      );

      // 결과 저장
      results['fps_$fps'] = testResult;

      // 기준과 비교한 오차 계산
      final errorMetrics = _calculateErrorMetrics(
        exactBaselineResult,
        testResult,
      );

      results['error_fps_$fps'] = errorMetrics;
    }

    return results;
  }

  /// 정확한 스텝으로 시뮬레이션 실행 (기준 생성용)
  Map<String, dynamic> _runExactStepSimulation(
    PhysicsEngine testEngine, {
    required double duration,
    required double stepSize,
  }) {
    // 결과 저장용 맵
    final objectPositions = <int, List<Vector2D>>{};
    final objectRotations = <int, List<double>>{};
    final timePoints = <double>[];

    // 객체 ID 목록 구성
    final objectIds = <int>[];
    for (int i = 0; i < testEngine._bodies.length; i++) {
      if (testEngine._bodies.containsKey(i)) {
        objectIds.add(i);
        objectPositions[i] = [];
        objectRotations[i] = [];
      }
    }

    // 시뮬레이션 실행
    double time = 0.0;
    while (time <= duration) {
      testEngine.stepSimulation(stepSize);
      time += stepSize;

      // 객체 상태 기록
      timePoints.add(time);
      for (final id in objectIds) {
        final body = testEngine.getBody(id);
        if (body != null) {
          objectPositions[id]!.add(Vector2D.copy(body.position));
          objectRotations[id]!.add(body.rotation);
        }
      }
    }

    return {
      'timePoints': timePoints,
      'positions': objectPositions,
      'rotations': objectRotations,
    };
  }

  /// 가변 프레임 레이트로 시뮬레이션 실행 (테스트용)
  Map<String, dynamic> _runVariableFrameRateSimulation({
    required double duration,
    required double targetFrameRate,
  }) {
    // 결과 저장용 맵
    final objectPositions = <int, List<Vector2D>>{};
    final objectRotations = <int, List<double>>{};
    final timePoints = <double>[];
    final actualFrameTimes = <double>[];

    // 객체 ID 목록 구성
    final objectIds = <int>[];
    for (int i = 0; i < engine._bodies.length; i++) {
      if (engine._bodies.containsKey(i)) {
        objectIds.add(i);
        objectPositions[i] = [];
        objectRotations[i] = [];
      }
    }

    // 프레임 시간 계산
    final targetFrameTime = 1.0 / targetFrameRate;

    // 시간 변동을 시뮬레이션하기 위한 무작위 요소 (±5% 변동)
    final frameTimeRandom = math.Random(42);

    // 시뮬레이션 실행
    double time = 0.0;
    while (time <= duration) {
      // 약간의 무작위 변동을 가진 프레임 시간 생성
      final frameVariance = targetFrameTime * 0.05; // 5% 변동
      final frameTime =
          targetFrameTime +
          (frameTimeRandom.nextDouble() * 2 - 1) * frameVariance;

      actualFrameTimes.add(frameTime);

      // 물리 업데이트
      engine.update(frameTime);
      time += frameTime;

      // 객체 상태 기록
      timePoints.add(time);
      for (final id in objectIds) {
        final body = engine.getBody(id);
        if (body != null) {
          // 보간된 위치/회전 저장
          objectPositions[id]!.add(Vector2D.copy(body.interpolatedPosition));
          objectRotations[id]!.add(body.interpolatedRotation);
        }
      }
    }

    return {
      'timePoints': timePoints,
      'positions': objectPositions,
      'rotations': objectRotations,
      'frameTimes': actualFrameTimes,
      'averageFrameRate':
          1.0 /
          (actualFrameTimes.reduce((a, b) => a + b) / actualFrameTimes.length),
    };
  }

  /// 오차 메트릭 계산
  Map<String, dynamic> _calculateErrorMetrics(
    Map<String, dynamic> baseline,
    Map<String, dynamic> testResult,
  ) {
    // 평균 위치 오차 계산
    final positionErrors = <int, double>{};
    final rotationErrors = <int, double>{};

    // 위치/회전 데이터
    final basePositions = baseline['positions'] as Map<int, List<Vector2D>>;
    final baseRotations = baseline['rotations'] as Map<int, List<double>>;
    final testPositions = testResult['positions'] as Map<int, List<Vector2D>>;
    final testRotations = testResult['rotations'] as Map<int, List<double>>;

    // 시간 데이터
    final baseTimePoints = baseline['timePoints'] as List<double>;
    final testTimePoints = testResult['timePoints'] as List<double>;

    // 각 객체별 오차 계산
    for (final id in basePositions.keys) {
      if (!testPositions.containsKey(id)) continue;

      // 위치 오차 계산을 위한 보간 사용
      double totalPositionError = 0.0;
      double totalRotationError = 0.0;
      int sampleCount = 0;

      // 테스트 결과의 각 시간 포인트에 대해 기준 데이터에서 보간하여 비교
      for (int i = 0; i < testTimePoints.length; i++) {
        final testTime = testTimePoints[i];

        // 샘플 범위 내의 시간 포인트만 사용
        if (testTime > baseTimePoints.last || testTime < baseTimePoints.first) {
          continue;
        }

        // 기준 데이터에서 해당 시간에 맞는 위치/회전 보간
        final basePosition = _interpolatePosition(
          baseTimePoints,
          basePositions[id]!,
          testTime,
        );
        final baseRotation = _interpolateRotation(
          baseTimePoints,
          baseRotations[id]!,
          testTime,
        );

        // 테스트 데이터의 해당 시간 위치/회전
        final testPosition = testPositions[id]![i];
        final testRotation = testRotations[id]![i];

        // 오차 계산
        final posError = Vector2D.distance(basePosition, testPosition);
        final rotError = _calculateAngleDifference(baseRotation, testRotation);

        totalPositionError += posError;
        totalRotationError += rotError;
        sampleCount++;
      }

      // 평균 오차 계산
      if (sampleCount > 0) {
        positionErrors[id] = totalPositionError / sampleCount;
        rotationErrors[id] = totalRotationError / sampleCount;
      }
    }

    // 전체 평균 오차 계산
    double avgPositionError = 0.0;
    double avgRotationError = 0.0;

    if (positionErrors.isNotEmpty) {
      avgPositionError =
          positionErrors.values.reduce((a, b) => a + b) / positionErrors.length;
      avgRotationError =
          rotationErrors.values.reduce((a, b) => a + b) / rotationErrors.length;
    }

    return {
      'avgPositionError': avgPositionError,
      'avgRotationError': avgRotationError,
      'positionErrorByObject': positionErrors,
      'rotationErrorByObject': rotationErrors,
    };
  }

  /// 위치 값 시간 보간
  Vector2D _interpolatePosition(
    List<double> timePoints,
    List<Vector2D> positions,
    double targetTime,
  ) {
    // 범위 내 위치 찾기
    for (int i = 0; i < timePoints.length - 1; i++) {
      if (targetTime >= timePoints[i] && targetTime <= timePoints[i + 1]) {
        // 보간 계수 계산
        final t =
            (targetTime - timePoints[i]) / (timePoints[i + 1] - timePoints[i]);

        // 선형 보간
        return Vector2D.lerp(positions[i], positions[i + 1], t);
      }
    }

    // 범위를 벗어나면 가장 가까운 값 반환
    if (targetTime <= timePoints.first) return positions.first;
    return positions.last;
  }

  /// 회전 값 시간 보간
  double _interpolateRotation(
    List<double> timePoints,
    List<double> rotations,
    double targetTime,
  ) {
    // 범위 내 위치 찾기
    for (int i = 0; i < timePoints.length - 1; i++) {
      if (targetTime >= timePoints[i] && targetTime <= timePoints[i + 1]) {
        // 보간 계수 계산
        final t =
            (targetTime - timePoints[i]) / (timePoints[i + 1] - timePoints[i]);

        // 각도 보간 (최단 경로)
        return _lerpAngle(rotations[i], rotations[i + 1], t);
      }
    }

    // 범위를 벗어나면 가장 가까운 값 반환
    if (targetTime <= timePoints.first) return rotations.first;
    return rotations.last;
  }

  /// 각도의 선형 보간 (최단 경로)
  double _lerpAngle(double a, double b, double t) {
    // 각도 차이 계산
    double diff = _normalizeAngle(b - a);

    // -PI와 PI 사이로 정규화
    if (diff > math.pi) {
      diff -= 2 * math.pi;
    } else if (diff < -math.pi) {
      diff += 2 * math.pi;
    }

    return _normalizeAngle(a + diff * t);
  }

  /// 각도를 0-2PI 범위로 정규화
  double _normalizeAngle(double angle) {
    const double twoPi = 2 * math.pi;
    return ((angle % twoPi) + twoPi) % twoPi;
  }

  /// 두 각도 사이의 최소 차이 계산
  double _calculateAngleDifference(double a, double b) {
    const double PI = math.pi;

    // 두 각도를 0-2PI 범위로 정규화
    a = _normalizeAngle(a);
    b = _normalizeAngle(b);

    // 차이 계산
    double diff = (a - b).abs();

    // 최소 차이 반환 (180도 초과 시 반대 방향이 더 가까움)
    return diff > PI ? 2 * PI - diff : diff;
  }
}
