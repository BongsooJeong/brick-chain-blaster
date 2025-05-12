import 'package:flutter_test/flutter_test.dart';
import 'package:brick_chain_blaster/physics/vector2d.dart';
import 'package:brick_chain_blaster/physics/physics_body.dart';
import 'package:brick_chain_blaster/physics/physics_engine.dart';
import 'package:brick_chain_blaster/physics/collision_detection.dart';
import 'package:brick_chain_blaster/models/game/shape.dart';

void main() {
  group('Narrow-Phase Collision Detection Tests', () {
    test('Circle vs Circle collision', () {
      // 두 원 생성
      final circleA = Circle(Vector2D(0, 0), 5);
      final circleB = Circle(Vector2D(8, 0), 5);

      // 충돌 검사
      final result = CollisionDetection.circleVsCircle(circleA, circleB);

      // 충돌 발생 확인
      expect(result.collides, true);

      // 침투 깊이 확인 (10 - 8 = 2)
      expect(result.depth, closeTo(2, 0.001));

      // 충돌 방향 확인 (오른쪽)
      expect(result.normal.x, closeTo(1, 0.001));
      expect(result.normal.y, closeTo(0, 0.001));
    });

    test('Circle vs Circle no collision', () {
      // 거리가 각 원의 반지름 합보다 큰 두 원
      final circleA = Circle(Vector2D(0, 0), 5);
      final circleB = Circle(Vector2D(12, 0), 5);

      // 충돌 검사
      final result = CollisionDetection.circleVsCircle(circleA, circleB);

      // 충돌 없음 확인
      expect(result.collides, false);
    });

    test('AABB vs AABB collision', () {
      // 두 AABB 생성
      final aabbA = AABB(Vector2D(0, 0), Vector2D(10, 10));
      final aabbB = AABB(Vector2D(5, 5), Vector2D(15, 15));

      // 충돌 검사
      final result = CollisionDetection.aabbVsAabb(aabbA, aabbB);

      // 충돌 발생 확인
      expect(result.collides, true);

      // 침투 깊이 확인 (x 방향 침투: 5, y 방향 침투: 5, 더 작은 값 선택)
      expect(result.depth, closeTo(5, 0.001));
    });

    test('AABB vs AABB no collision', () {
      // 겹치지 않는 두 AABB
      final aabbA = AABB(Vector2D(0, 0), Vector2D(10, 10));
      final aabbB = AABB(Vector2D(15, 15), Vector2D(25, 25));

      // 충돌 검사
      final result = CollisionDetection.aabbVsAabb(aabbA, aabbB);

      // 충돌 없음 확인
      expect(result.collides, false);
    });

    test('Circle vs AABB collision', () {
      // 원과 AABB 생성
      final circle = Circle(Vector2D(10, 10), 5);
      final aabb = AABB(Vector2D(12, 8), Vector2D(22, 18));

      // 충돌 검사
      final result = CollisionDetection.circleVsAabb(circle, aabb);

      // 충돌 발생 확인
      expect(result.collides, true);
    });

    test('Circle vs AABB no collision', () {
      // 충돌하지 않는 원과 AABB
      final circle = Circle(Vector2D(0, 0), 3);
      final aabb = AABB(Vector2D(10, 10), Vector2D(20, 20));

      // 충돌 검사
      final result = CollisionDetection.circleVsAabb(circle, aabb);

      // 충돌 없음 확인
      expect(result.collides, false);
    });

    test('Polygon vs Polygon collision (SAT)', () {
      // 두 다각형 생성 (사각형)
      final poly1 = Polygon([
        Vector2D(0, 0),
        Vector2D(10, 0),
        Vector2D(10, 10),
        Vector2D(0, 10),
      ]);

      final poly2 = Polygon([
        Vector2D(5, 5),
        Vector2D(15, 5),
        Vector2D(15, 15),
        Vector2D(5, 15),
      ]);

      // 충돌 검사
      final result = CollisionDetection.satPolygons(poly1, poly2);

      // 충돌 발생 확인
      expect(result.collides, true);
    });

    test('Polygon vs Polygon no collision (SAT)', () {
      // 충돌하지 않는 두 다각형
      final poly1 = Polygon([
        Vector2D(0, 0),
        Vector2D(10, 0),
        Vector2D(10, 10),
        Vector2D(0, 10),
      ]);

      final poly2 = Polygon([
        Vector2D(15, 15),
        Vector2D(25, 15),
        Vector2D(25, 25),
        Vector2D(15, 25),
      ]);

      // 충돌 검사
      final result = CollisionDetection.satPolygons(poly1, poly2);

      // 충돌 없음 확인
      expect(result.collides, false);
    });

    test('물리 엔진에서 충돌 검출 - Circle vs Circle', () {
      // 물리 엔진 생성
      final engine = PhysicsEngine();

      // 두 바디 생성
      final bodyA = PhysicsBody(
        id: 1,
        shape: Circle(Vector2D(0, 0), 5),
        position: Vector2D(0, 0),
      );

      final bodyB = PhysicsBody(
        id: 2,
        shape: Circle(Vector2D(0, 0), 5),
        position: Vector2D(8, 0),
      );

      // 바디 추가
      engine.addBody(bodyA);
      engine.addBody(bodyB);

      // 물리 업데이트
      engine.update(1 / 60);

      // 충돌이 발생했는지 확인
      expect(engine.debugMode, false); // 기본은 디버깅 모드 아님

      // 디버깅 모드 켜기
      engine.debugMode = true;
      engine.update(1 / 60);

      // 충돌 수 확인
      expect(engine.debugInfo.collisions.isNotEmpty, true);
    });

    test('연속 충돌 감지 (CCD) - 빠르게 이동하는 Circle', () {
      // 두 원 생성
      final bodyA = PhysicsBody(
        id: 1,
        shape: Circle(Vector2D(0, 0), 5),
        position: Vector2D(0, 0),
        velocity: Vector2D(100, 0), // 매우 빠른 속도
      );

      final bodyB = PhysicsBody(
        id: 2,
        shape: Circle(Vector2D(0, 0), 5),
        position: Vector2D(50, 0),
        velocity: Vector2D(0, 0), // 정지 상태
      );

      // CCD 테스트
      final result = CollisionDetection.sweepTest(bodyA, bodyB, 1 / 60);

      // 1/60초 내에 충돌 발생 확인
      expect(result.collision, true);

      // 충돌 시간 확인 (첫 프레임에서 곧바로 충돌하진 않음)
      expect(result.time > 0, true);
      expect(result.time < 1 / 60, true);
    });
  });
}
