import 'vector2d.dart';

/// Verlet 적분 방식을 구현한 클래스
/// 위치 기반 시뮬레이션으로 안정적인 물리 계산 제공
class VerletIntegrator {
  /// 이전 위치 캐시 (ID → Vector2D)
  final Map<int, Vector2D> _previousPositions = {};

  /// 이전 회전 캐시 (ID → double)
  final Map<int, double> _previousRotations = {};

  /// 반감쇠 계수 (0.0-1.0)
  double dampingFactor;

  /// 생성자
  VerletIntegrator({this.dampingFactor = 0.98});

  /// 초기 상태 설정
  void initializeState(int bodyId, Vector2D position, double rotation) {
    _previousPositions[bodyId] = Vector2D.copy(position);
    _previousRotations[bodyId] = rotation;
  }

  /// 객체 제거
  void removeBody(int bodyId) {
    _previousPositions.remove(bodyId);
    _previousRotations.remove(bodyId);
  }

  /// 이전 위치 가져오기
  Vector2D getPreviousPosition(int bodyId) {
    if (!_previousPositions.containsKey(bodyId)) {
      return Vector2D.zero();
    }
    return _previousPositions[bodyId]!;
  }

  /// 이전 회전 가져오기
  double getPreviousRotation(int bodyId) {
    if (!_previousRotations.containsKey(bodyId)) {
      return 0.0;
    }
    return _previousRotations[bodyId]!;
  }

  /// 위치 업데이트 (Verlet 적분)
  Vector2D integratePosition(
    int bodyId,
    Vector2D currentPosition,
    Vector2D acceleration,
    double dt,
  ) {
    // 이전 위치가 없으면 초기화
    if (!_previousPositions.containsKey(bodyId)) {
      _previousPositions[bodyId] = Vector2D.copy(currentPosition);
      return currentPosition;
    }

    // 현재 위치 저장
    final previousPosition = _previousPositions[bodyId]!;

    // Verlet 적분 공식 적용
    final velocity = (currentPosition - previousPosition) * dampingFactor;
    final newPosition = currentPosition + velocity + acceleration * dt * dt;

    // 이전 위치 업데이트
    _previousPositions[bodyId] = Vector2D.copy(currentPosition);

    return newPosition;
  }

  /// 회전 업데이트 (Verlet 적분)
  double integrateRotation(
    int bodyId,
    double currentRotation,
    double angularAcceleration,
    double dt,
  ) {
    // 이전 회전이 없으면 초기화
    if (!_previousRotations.containsKey(bodyId)) {
      _previousRotations[bodyId] = currentRotation;
      return currentRotation;
    }

    // 이전 회전값
    final previousRotation = _previousRotations[bodyId]!;

    // 각속도 계산
    final angularVelocity =
        (currentRotation - previousRotation) * dampingFactor;

    // Verlet 적분 공식 적용
    final newRotation =
        currentRotation + angularVelocity + angularAcceleration * dt * dt;

    // 이전 회전값 업데이트
    _previousRotations[bodyId] = currentRotation;

    return newRotation;
  }

  /// 모든 캐시 초기화
  void clear() {
    _previousPositions.clear();
    _previousRotations.clear();
  }
}
