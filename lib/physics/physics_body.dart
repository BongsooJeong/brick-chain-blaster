import 'dart:math' as math;
import '../models/game/shape.dart';
import 'vector2d.dart';
import 'frame_state.dart';
import 'material_properties.dart';

/// 물리 바디의 타입 (물리적 동작 방식)
enum BodyType {
  /// 정적 바디 - 위치 고정, 충돌 응답 X
  static,

  /// 동적 바디 - 물리 시뮬레이션에 완전히 참여
  dynamic,

  /// 키네마틱 바디 - 프로그래밍 방식으로 이동, 충돌 응답 X
  kinematic,
}

/// 물리 바디의 충돌 레이어 (비트 플래그)
class CollisionLayer {
  static const int DEFAULT = 0x0001;
  static const int BALL = 0x0002;
  static const int BRICK = 0x0004;
  static const int WALL = 0x0008;
  static const int POWERUP = 0x0010;
  static const int PADDLE = 0x0020;
}

/// 물리 바디 클래스 - 물리적으로 시뮬레이션되는 객체
class PhysicsBody {
  /// 고유 식별자
  final int id;

  /// 바디 타입
  BodyType type;

  /// 위치 벡터
  Vector2D position;

  /// 속도 벡터
  Vector2D velocity;

  /// 회전 (라디안)
  double rotation;

  /// 각속도 (라디안/초)
  double angularVelocity;

  /// 힘 누적
  Vector2D force;

  /// 토크 누적
  double torque;

  /// 질량 (kg)
  double mass;

  /// 역질량 (1/kg) - 계산 최적화용
  double inverseMass;

  /// 관성 모멘트
  double inertia;

  /// 역관성 모멘트 - 계산 최적화용
  double inverseInertia;

  /// 모양
  Shape shape;

  /// 재질 속성
  MaterialProperties material;

  /// 반발계수 (0~1) - 충돌 시 에너지 보존 정도
  double get restitution => material.restitution;

  /// 정지 마찰 계수
  double get staticFriction => material.staticFriction;

  /// 운동 마찰 계수
  double get dynamicFriction => material.dynamicFriction;

  /// 선형 감쇠 (속도 감소)
  double linearDamping;

  /// 각 감쇠 (회전 속도 감소)
  double angularDamping;

  /// 충돌 레이어 (비트 마스크)
  int collisionLayer;

  /// 충돌 마스크 (이 바디가 충돌할 수 있는 레이어)
  int collisionMask;

  /// 사용자 정의 데이터
  dynamic userData;

  /// 휴면 상태 여부 (최적화용)
  bool isSleeping = false;

  /// 보간된 상태 (렌더링용)
  FrameState? _interpolatedState;

  /// 이전 상태 (보간용)
  FrameState? _previousState;

  /// 현재 상태 (보간용)
  FrameState? _currentState;

  PhysicsBody({
    required this.id,
    required this.shape,
    this.type = BodyType.dynamic,
    Vector2D? position,
    Vector2D? velocity,
    this.rotation = 0.0,
    this.angularVelocity = 0.0,
    this.mass = 1.0,
    double? inertia,
    MaterialProperties? material,
    double restitution = 0.2,
    double staticFriction = 0.5,
    double dynamicFriction = 0.3,
    this.linearDamping = 0.01,
    this.angularDamping = 0.01,
    this.collisionLayer = CollisionLayer.DEFAULT,
    this.collisionMask = 0xFFFF,
    this.userData,
  }) : position = position ?? Vector2D.zero(),
       velocity = velocity ?? Vector2D.zero(),
       force = Vector2D.zero(),
       torque = 0.0,
       inverseMass = mass > 0 ? 1.0 / mass : 0.0,
       inertia = inertia ?? 0.0,
       inverseInertia = inertia != null && inertia > 0 ? 1.0 / inertia : 0.0,
       material =
           material ??
           MaterialProperties(
             restitution: restitution,
             staticFriction: staticFriction,
             dynamicFriction: dynamicFriction,
           ) {
    if (type == BodyType.static) {
      inverseMass = 0;
      inverseInertia = 0;
    }

    // 초기 상태 설정
    _currentState = FrameState(
      position: Vector2D.copy(this.position),
      rotation: rotation,
    );
    _previousState = FrameState.copy(_currentState!);
    _interpolatedState = FrameState.copy(_currentState!);
  }

  /// AABB 경계 상자 가져오기
  AABB get aabb => shape.boundingBox;

  /// 보간된 위치 가져오기 (렌더링용)
  Vector2D get interpolatedPosition => _interpolatedState?.position ?? position;

  /// 보간된 회전 가져오기 (렌더링용)
  double get interpolatedRotation => _interpolatedState?.rotation ?? rotation;

  /// 상태 업데이트 - 물리 시뮬레이션 후 호출
  void updateStates() {
    _previousState = _currentState;
    _currentState = FrameState(
      position: Vector2D.copy(position),
      rotation: rotation,
    );
  }

  /// 보간 상태 계산 - 렌더링 전 호출
  void interpolate(double alpha) {
    if (_previousState == null || _currentState == null) {
      _interpolatedState = FrameState(
        position: Vector2D.copy(position),
        rotation: rotation,
      );
      return;
    }

    _interpolatedState = FrameState.lerp(
      _previousState!,
      _currentState!,
      alpha,
    );
  }

  /// 충돌 필터링 - 두 바디가 충돌할 수 있는지 확인
  bool canCollideWith(PhysicsBody other) {
    return (collisionMask & other.collisionLayer) != 0 &&
        (other.collisionMask & collisionLayer) != 0;
  }

  /// 힘 적용
  void applyForce(Vector2D force) {
    this.force = this.force + force;
    if (isSleeping) {
      isSleeping = false;
    }
  }

  /// 특정 지점에 힘 적용 (토크 발생)
  void applyForceAtPoint(Vector2D force, Vector2D point) {
    this.force = this.force + force;

    // 회전축으로부터의 상대 위치
    final relativePoint = point - position;

    // 토크 계산 (2D에서는 외적의 z값)
    torque += relativePoint.cross(force);

    if (isSleeping) {
      isSleeping = false;
    }
  }

  /// 특정 지점에서의 속도 계산
  ///
  /// [r]는 물체의 중심에서 특정 지점까지의 상대적인 벡터입니다.
  /// 결과는 해당 지점에서의 총 선형 속도입니다 (선형 속도 + 회전에 의한 선형 속도).
  Vector2D getVelocityAtPoint(Vector2D r) {
    // v = 물체의 선형 속도 + 회전 속도에 의한 접선 속도
    // 접선 속도 = ω × r = (0, 0, ω) × (r.x, r.y, 0) = (-ω * r.y, ω * r.x, 0)
    return velocity + Vector2D(-angularVelocity * r.y, angularVelocity * r.x);
  }

  /// 충격량 적용 (즉각적인 속도 변화)
  void applyImpulse(Vector2D impulse) {
    velocity = velocity + impulse * inverseMass;
    if (isSleeping) {
      isSleeping = false;
    }
  }

  /// 특정 지점에 충격량 적용 (회전 속도 변화)
  void applyImpulseAtPoint(Vector2D impulse, Vector2D point) {
    velocity = velocity + impulse * inverseMass;

    // 회전축으로부터의 상대 위치
    final relativePoint = point - position;

    // 각운동량 변화
    angularVelocity += relativePoint.cross(impulse) * inverseInertia;

    if (isSleeping) {
      isSleeping = false;
    }
  }

  /// 재질 속성 변경
  void setMaterial(MaterialProperties newMaterial) {
    material = newMaterial;
  }
}

/// 수학 유틸리티 함수
double sqrt(double x) => x <= 0 ? 0 : math.sqrt(x);
double pow(double x, double y) => x == 0 ? 0 : math.pow(x, y).toDouble();
