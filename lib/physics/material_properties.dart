import 'dart:math' as math;

/// 물리 시뮬레이션에서 사용되는 재질의 속성을 정의하는 클래스
class MaterialProperties {
  /// 반발계수 (0.0 ~ 1.0)
  /// 충돌 시 에너지 손실 정도를 결정합니다.
  /// 1.0은 완전 탄성 충돌, 0.0은 완전 비탄성 충돌을 의미합니다.
  final double restitution;

  /// 정적 마찰 계수 (0.0 ~ 1.0+)
  /// 물체가 움직이기 시작하기 전까지의 마찰력을 결정합니다.
  final double staticFriction;

  /// 동적 마찰 계수 (0.0 ~ 1.0+)
  /// 물체가 움직이는 동안의 마찰력을 결정합니다.
  final double dynamicFriction;

  /// 밀도 (kg/m^2)
  /// 단위 면적당 질량을 결정합니다.
  final double density;

  /// 생성자
  const MaterialProperties({
    this.restitution = 0.2,
    this.staticFriction = 0.5,
    this.dynamicFriction = 0.3,
    this.density = 1.0,
  });

  /// 사전 정의된 재질: 고무
  static const MaterialProperties rubber = MaterialProperties(
    restitution: 0.8,
    staticFriction: 0.9,
    dynamicFriction: 0.7,
    density: 1.5,
  );

  /// 사전 정의된 재질: 유리
  static const MaterialProperties glass = MaterialProperties(
    restitution: 0.4,
    staticFriction: 0.4,
    dynamicFriction: 0.2,
    density: 2.5,
  );

  /// 사전 정의된 재질: 금속
  static const MaterialProperties metal = MaterialProperties(
    restitution: 0.1,
    staticFriction: 0.6,
    dynamicFriction: 0.3,
    density: 8.0,
  );

  /// 사전 정의된 재질: 나무
  static const MaterialProperties wood = MaterialProperties(
    restitution: 0.3,
    staticFriction: 0.7,
    dynamicFriction: 0.5,
    density: 0.6,
  );

  /// 사전 정의된 재질: 얼음
  static const MaterialProperties ice = MaterialProperties(
    restitution: 0.1,
    staticFriction: 0.1,
    dynamicFriction: 0.03,
    density: 0.9,
  );

  /// 사전 정의된 재질: 바운스 볼
  static const MaterialProperties bouncyBall = MaterialProperties(
    restitution: 0.95,
    staticFriction: 0.4,
    dynamicFriction: 0.2,
    density: 0.3,
  );

  /// 두 재질 간의 복합 재질 속성 계산
  static MaterialProperties combine(
    MaterialProperties a,
    MaterialProperties b,
  ) {
    return MaterialProperties(
      // 반발계수는 두 재질 중 작은 값을 사용 (보수적 접근)
      restitution: math.min(a.restitution, b.restitution),

      // 마찰계수는 두 재질의 기하평균 사용
      staticFriction: _geometricMean(a.staticFriction, b.staticFriction),
      dynamicFriction: _geometricMean(a.dynamicFriction, b.dynamicFriction),

      // 밀도는 평균값 사용
      density: (a.density + b.density) / 2,
    );
  }

  /// 기하평균 계산 (마찰계수 조합에 사용)
  static double _geometricMean(double a, double b) {
    return math.sqrt((a * b).abs());
  }
}

/// 확장 메서드 - 양수에 대한 제곱근
extension DoubleExtension on double {
  double sqrt() => this <= 0 ? 0 : math.sqrt(this);
}
