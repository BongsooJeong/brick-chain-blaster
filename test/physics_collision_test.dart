import 'package:flutter_test/flutter_test.dart';
import 'package:brick_chain_blaster/physics/physics_engine.dart';
import 'package:brick_chain_blaster/physics/physics_test_util.dart';
import 'package:brick_chain_blaster/physics/vector2d.dart';
import 'package:brick_chain_blaster/physics/physics_body.dart';
import 'dart:math' as math;

void main() {
  group('Physics Engine Broad-phase Collision Detection Tests', () {
    late PhysicsEngine engine;
    late PhysicsTestUtil testUtil;

    setUp(() {
      // 물리 엔진 초기화 (디버깅 모드 활성화)
      engine = PhysicsEngine(
        gravity: Vector2D(0, 0), // 테스트를 위해 중력 비활성화
        fixedTimeStep: 1 / 60,
        velocityIterations: 8,
        positionIterations: 3,
        substeps: 1,
        debugMode: true,
      );

      testUtil = PhysicsTestUtil(engine, seed: 42); // 재현 가능한 결과를 위한 고정 시드
    });

    test('Random scene generation and collision detection', () {
      // 무작위 장면 생성
      final objectIds = testUtil.createRandomScene(
        objectCount: 50,
        arenaWidth: 800,
        arenaHeight: 600,
        initialVelocityMax: 0, // 정적인 상태에서 충돌 테스트
      );

      // 물리 스텝 수행 전 상태 기록
      final initialPositions =
          objectIds.map((id) => engine.getBody(id)!.position).toList();

      // 물리 시뮬레이션 1스텝 수행
      engine.stepSimulation(1 / 60);

      // 충돌 발생 여부 확인
      final collisionCount = engine.debugInfo.stats['collisionCount'];
      print('첫 단계의 충돌 수: $collisionCount');

      // 여러 시간 스텝 시뮬레이션 후 충돌 기록
      for (int i = 0; i < 10; i++) {
        engine.stepSimulation(1 / 60);
      }

      // 총 충돌 수 확인
      final totalCollisions = engine.debugInfo.collisions.length;
      print('총 충돌 수: $totalCollisions');

      // 충돌이 발생했는지 확인
      expect(totalCollisions, greaterThan(0));
    });

    test('Performance comparison of different collision detection methods', () {
      // 다양한 물체 수에 따른 성능 측정
      final objectCounts = [10, 50, 100, 200];
      final results = <int, Map<String, dynamic>>{};

      for (final count in objectCounts) {
        engine.clearBodies();
        engine.debugInfo.clear();

        // 객체 생성
        testUtil.createRandomScene(
          objectCount: count,
          arenaWidth: 800,
          arenaHeight: 600,
          initialVelocityMax: 50,
        );

        // 성능 측정
        final startTime = DateTime.now().millisecondsSinceEpoch;

        // 여러 스텝 실행
        for (int i = 0; i < 60; i++) {
          engine.stepSimulation(1 / 60);
        }

        final endTime = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = endTime - startTime;

        results[count] = {
          'time': elapsedMs,
          'collisionCount': engine.debugInfo.collisions.length,
          'framesPerSecond': 60 * 1000 / elapsedMs,
        };

        print(
          '물체 $count개: ${elapsedMs}ms (${results[count]!['framesPerSecond']} FPS), 충돌 ${results[count]!['collisionCount']}회',
        );
      }

      // 적은 물체 수와 많은 물체 수의 시간 차이 측정
      final speedupRatio =
          results[objectCounts.last]!['time'] /
          results[objectCounts.first]!['time'];
      print('속도 차이 비율: $speedupRatio배');

      // 물체 수가 증가해도 처리 시간이 선형 이상으로 증가하지 않아야 함
      // (브로드 페이즈 최적화의 효과)
      expect(
        speedupRatio,
        lessThan(objectCounts.last / objectCounts.first * 2),
      );
    });

    test('Grid-based vs. Brute force collision detection', () {
      // 테스트 준비
      final largeObjectCount = 200;
      final setupTime = DateTime.now().millisecondsSinceEpoch;

      // 많은 물체로 장면 생성
      testUtil.createRandomScene(
        objectCount: largeObjectCount,
        arenaWidth: 800,
        arenaHeight: 600,
        initialVelocityMax: 20,
      );

      // 그리드 기반 광범위 충돌 감지 시간 측정
      final startGridTime = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 30; i++) {
        engine.stepSimulation(1 / 60);
      }
      final endGridTime = DateTime.now().millisecondsSinceEpoch;
      final gridTimeMs = endGridTime - startGridTime;

      print('그리드 기반 광범위 충돌 감지 ($largeObjectCount개 물체): ${gridTimeMs}ms');
      print('평균 프레임 레이트: ${30 * 1000 / gridTimeMs} FPS');

      // 충돌 수, 활성 물체 수 정보 출력
      print('활성 물체 수: ${engine.debugInfo.stats['activeBodyCount']}');
      print('총 충돌 수: ${engine.debugInfo.collisions.length}');

      // 의미 있는 충돌이 감지되었는지 확인
      expect(engine.debugInfo.collisions.length, greaterThan(0));

      // 성능이 허용 가능한 수준인지 확인
      expect(30 * 1000 / gridTimeMs, greaterThan(30)); // 최소 30 FPS
    });

    test('Comparison of different broadphase methods', () {
      // 테스트할 방법들
      final methods = [
        BroadphaseMethod.grid,
        BroadphaseMethod.quadTree,
        BroadphaseMethod.aabbTree,
      ];

      final methodNames = ['그리드 기반', '쿼드트리 기반', 'AABB 트리 기반'];

      // 고정된 객체 수
      final objectCount = 300;

      // 각 방법의 성능 측정 결과
      final results = <BroadphaseMethod, Map<String, dynamic>>{};

      for (int i = 0; i < methods.length; i++) {
        final method = methods[i];

        // 엔진 초기화
        engine.clearBodies();
        engine.debugInfo.clear();
        engine.broadphaseMethod = method;

        // 테스트 객체 생성
        testUtil.createRandomScene(
          objectCount: objectCount,
          arenaWidth: 800,
          arenaHeight: 600,
          initialVelocityMax: 50,
        );

        // 시뮬레이션 및 성능 측정
        final startTime = DateTime.now().millisecondsSinceEpoch;
        for (int j = 0; j < 60; j++) {
          engine.stepSimulation(1 / 60);
        }
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = endTime - startTime;

        // 결과 저장
        results[method] = {
          'time': elapsedMs,
          'fps': 60 * 1000 / elapsedMs,
          'collisions': engine.debugInfo.collisions.length,
          'broadphaseTime': engine.debugInfo.stats['broadphaseTime'],
          'pairCount': engine.debugInfo.stats['pairCount'],
        };

        print(
          '${methodNames[i]} ($objectCount개 물체): '
          '${elapsedMs}ms (${results[method]!['fps']} FPS), '
          '충돌 ${results[method]!['collisions']}회, '
          '광범위 충돌 감지 시간: ${results[method]!['broadphaseTime']}ms, '
          '충돌 쌍 수: ${results[method]!['pairCount']}',
        );
      }

      // 결과 비교 및 검증
      if (results.length >= 2) {
        for (int i = 1; i < methods.length; i++) {
          final baseMethod = methods[0];
          final compMethod = methods[i];

          if (results.containsKey(baseMethod) &&
              results.containsKey(compMethod)) {
            final baseTime = results[baseMethod]!['time'] as num;
            final compTime = results[compMethod]!['time'] as num;

            final speedup = baseTime / compTime;
            print(
              '${methodNames[i]} vs ${methodNames[0]} 속도 비교: ${speedup.toStringAsFixed(2)}배',
            );

            // 다른 방법이 기준 방법보다 지나치게 느리지 않아야 함
            expect(compTime, lessThan(baseTime * 2));
          }
        }
      }
    });

    test('Static body caching optimization', () {
      // 객체 수
      final objectCount = 200;

      // 정적 캐싱 활성화 상태에서 측정
      engine.clearBodies();
      engine.debugInfo.clear();
      engine.useStaticBodyCaching = true;

      // 테스트 객체 생성 (50%는 정적 객체)
      final random = math.Random(42);
      testUtil.createRandomScene(
        objectCount: objectCount,
        arenaWidth: 800,
        arenaHeight: 600,
        initialVelocityMax: 0, // 정적 상태 테스트
      );

      // 정적 객체로 변환
      final staticCount = objectCount ~/ 2;
      int converted = 0;
      for (
        int i = 0;
        i < engine.bodies.length && converted < staticCount;
        i++
      ) {
        if (engine.bodies.containsKey(i) && random.nextBool()) {
          final body = engine.bodies[i]!;
          body.type = BodyType.static;
          converted++;
        }
      }

      // 캐싱 활성화 상태에서 성능 측정
      final startCachingTime = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 60; i++) {
        engine.stepSimulation(1 / 60);
      }
      final endCachingTime = DateTime.now().millisecondsSinceEpoch;
      final cachingTimeMs = endCachingTime - startCachingTime;

      // 정적 캐싱 비활성화 상태에서 측정
      engine.clearBodies();
      engine.debugInfo.clear();
      engine.useStaticBodyCaching = false;

      // 동일한 테스트 객체 재생성
      testUtil = PhysicsTestUtil(engine, seed: 42);
      testUtil.createRandomScene(
        objectCount: objectCount,
        arenaWidth: 800,
        arenaHeight: 600,
        initialVelocityMax: 0,
      );

      // 정적 객체로 변환 (동일하게)
      converted = 0;
      for (
        int i = 0;
        i < engine.bodies.length && converted < staticCount;
        i++
      ) {
        if (engine.bodies.containsKey(i) && random.nextBool()) {
          final body = engine.bodies[i]!;
          body.type = BodyType.static;
          converted++;
        }
      }

      // 캐싱 비활성화 상태에서 성능 측정
      final startNoCachingTime = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 60; i++) {
        engine.stepSimulation(1 / 60);
      }
      final endNoCachingTime = DateTime.now().millisecondsSinceEpoch;
      final noCachingTimeMs = endNoCachingTime - startNoCachingTime;

      // 결과 출력
      print(
        '정적 물체 캐싱 활성화: ${cachingTimeMs}ms (${60 * 1000 / cachingTimeMs} FPS)',
      );
      print(
        '정적 물체 캐싱 비활성화: ${noCachingTimeMs}ms (${60 * 1000 / noCachingTimeMs} FPS)',
      );

      final speedup = noCachingTimeMs / cachingTimeMs;
      print('정적 물체 캐싱 성능 개선: ${speedup.toStringAsFixed(2)}배');

      // 캐싱 활성화가 비활성화보다 같거나 빨라야 함
      expect(cachingTimeMs, lessThanOrEqualTo(noCachingTimeMs));
    });
  });
}
