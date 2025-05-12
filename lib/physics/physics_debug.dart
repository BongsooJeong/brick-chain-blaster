import 'dart:collection';
import 'vector2d.dart';
import 'collision.dart';
import 'physics_body.dart';

/// 물리 엔진 디버깅 정보
class PhysicsDebugInfo {
  /// 물리 시뮬레이션 통계
  final Map<String, double> stats = {};

  /// 충돌 정보
  final List<Collision> collisions = [];

  /// 바디 추적 정보
  final Map<int, List<PhysicsBodyTracking>> bodyTracking = {};

  /// FPS 기록
  final Queue<double> fpsHistory = Queue<double>();

  /// 최대 FPS 기록 유지 수
  final int maxFpsHistory;

  /// 최대 충돌 기록 수
  final int maxCollisionHistory;

  PhysicsDebugInfo({this.maxFpsHistory = 60, this.maxCollisionHistory = 20});

  /// FPS 데이터 추가
  void addFpsDataPoint(double fps) {
    fpsHistory.add(fps);

    // 최대 크기 유지
    while (fpsHistory.length > maxFpsHistory) {
      fpsHistory.removeFirst();
    }
  }

  /// 충돌 데이터 추가
  void addCollision(Collision collision) {
    collisions.add(collision);

    // 최대 크기 유지
    while (collisions.length > maxCollisionHistory) {
      collisions.removeAt(0);
    }
  }

  /// 특정 물리 바디 추적 시작
  void trackBody(int bodyId) {
    bodyTracking[bodyId] = [];
  }

  /// 물리 바디 추적 중지
  void stopTrackingBody(int bodyId) {
    bodyTracking.remove(bodyId);
  }

  /// 추적 중인 바디 데이터 기록
  void recordBodyData(int bodyId, PhysicsBody body) {
    if (!bodyTracking.containsKey(bodyId)) {
      return;
    }

    final tracking = bodyTracking[bodyId]!;

    tracking.add(
      PhysicsBodyTracking(
        position: Vector2D.copy(body.position),
        velocity: Vector2D.copy(body.velocity),
        force: Vector2D.copy(body.force),
        rotation: body.rotation,
        angularVelocity: body.angularVelocity,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // 최대 100개 데이터포인트만 유지
    if (tracking.length > 100) {
      tracking.removeAt(0);
    }
  }

  /// 디버그 정보 초기화
  void clear() {
    stats.clear();
    collisions.clear();
    bodyTracking.clear();
    fpsHistory.clear();
  }
}

/// 물리 바디 추적 데이터
class PhysicsBodyTracking {
  final Vector2D position;
  final Vector2D velocity;
  final Vector2D force;
  final double rotation;
  final double angularVelocity;
  final int timestamp;

  PhysicsBodyTracking({
    required this.position,
    required this.velocity,
    required this.force,
    required this.rotation,
    required this.angularVelocity,
    required this.timestamp,
  });
}
