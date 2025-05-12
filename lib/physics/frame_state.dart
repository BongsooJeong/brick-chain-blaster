import 'vector2d.dart';

/// 물리 객체의 단일 프레임 상태를 저장하는 클래스
/// 프레임 간 보간에 사용됩니다.
class FrameState {
  /// 위치
  final Vector2D position;

  /// 회전 (라디안)
  final double rotation;

  /// 생성자
  FrameState({required this.position, required this.rotation});

  /// 복사 생성자
  FrameState.copy(FrameState other)
    : position = Vector2D.copy(other.position),
      rotation = other.rotation;

  /// 두 상태 사이의 선형 보간
  static FrameState lerp(FrameState a, FrameState b, double t) {
    return FrameState(
      position: Vector2D.lerp(a.position, b.position, t),
      rotation: _lerpAngle(a.rotation, b.rotation, t),
    );
  }

  /// 각도의 선형 보간 (최단 경로)
  static double _lerpAngle(double a, double b, double t) {
    // 각도 차이 계산
    double diff = _normalizeAngle(b - a);

    // -PI와 PI 사이로 정규화
    if (diff > 3.14159265358979) {
      diff -= 2 * 3.14159265358979;
    } else if (diff < -3.14159265358979) {
      diff += 2 * 3.14159265358979;
    }

    return _normalizeAngle(a + diff * t);
  }

  /// 각도를 0-2PI 범위로 정규화
  static double _normalizeAngle(double angle) {
    const double twoPi = 2 * 3.14159265358979;
    return ((angle % twoPi) + twoPi) % twoPi;
  }
}
