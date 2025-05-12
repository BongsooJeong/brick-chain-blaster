import 'dart:math' as math;
import '../input/input_manager.dart';
import '../input/input_event.dart';
import '../input/input_mapping.dart'; // ActionType 정의가 있는 파일
import 'physics_engine.dart';
import 'physics_body.dart';
import 'vector2d.dart';

/// 입력 액션 처리 핸들러 타입
typedef PhysicsActionHandler =
    void Function(String actionId, ActionEvent event, PhysicsEngine engine);

/// 물리 시스템과 입력 시스템 간의 연결 브릿지 클래스
class PhysicsInputBridge {
  /// 물리 엔진 레퍼런스
  final PhysicsEngine _physicsEngine;

  /// 입력 관리자 레퍼런스
  final InputManager _inputManager;

  /// 바디 ID -> 액션 ID 맵핑
  final Map<int, Map<String, String>> _bodyActionMap = {};

  /// 액션 ID -> 커스텀 핸들러 맵핑
  final Map<String, PhysicsActionHandler> _actionHandlers = {};

  /// 객체 조작 민감도
  double movementSensitivity;

  /// 회전 조작 민감도
  double rotationSensitivity;

  /// 힘 적용 계수
  double forceMultiplier;

  /// 충격량 적용 계수
  double impulseMultiplier;

  /// 대상 바디 맵
  final Map<String, int> _targetBodies = {};

  /// 액션 이벤트 구독 핸들
  late final Stream<ActionEvent> _actionStream;

  /// 초기화 여부
  bool _initialized = false;

  /// 생성자
  PhysicsInputBridge({
    required PhysicsEngine physicsEngine,
    required InputManager inputManager,
    this.movementSensitivity = 1.0,
    this.rotationSensitivity = 0.1,
    this.forceMultiplier = 10.0,
    this.impulseMultiplier = 1.0,
  }) : _physicsEngine = physicsEngine,
       _inputManager = inputManager {
    _actionStream = _inputManager.actionEvents;
  }

  /// 초기화 및 이벤트 구독
  void initialize() {
    if (_initialized) return;

    // 입력 이벤트 스트림 구독
    _actionStream.listen(_handleActionEvent);

    _initialized = true;
  }

  /// 물리 바디와 액션 간의 매핑 추가
  void mapBodyToAction(int bodyId, String actionMapId, String actionId) {
    if (!_bodyActionMap.containsKey(bodyId)) {
      _bodyActionMap[bodyId] = {};
    }

    _bodyActionMap[bodyId]![actionMapId] = actionId;
  }

  /// 물리 바디와 액션 간의 매핑 제거
  void unmapBodyFromAction(int bodyId, String actionMapId) {
    if (_bodyActionMap.containsKey(bodyId)) {
      _bodyActionMap[bodyId]!.remove(actionMapId);

      // 매핑이 비어있으면 바디도 제거
      if (_bodyActionMap[bodyId]!.isEmpty) {
        _bodyActionMap.remove(bodyId);
      }
    }
  }

  /// 액션에 대한 커스텀 핸들러 등록
  void registerActionHandler(String actionId, PhysicsActionHandler handler) {
    _actionHandlers[actionId] = handler;
  }

  /// 액션에 대한 커스텀 핸들러 제거
  void unregisterActionHandler(String actionId) {
    _actionHandlers.remove(actionId);
  }

  /// 대상 바디 설정
  void setTargetBody(String key, int bodyId) {
    _targetBodies[key] = bodyId;
  }

  /// 대상 바디 제거
  void removeTargetBody(String key) {
    _targetBodies.remove(key);
  }

  /// 대상 바디 가져오기
  int? getTargetBodyId(String key) {
    return _targetBodies[key];
  }

  /// 대상 바디 가져오기
  PhysicsBody? getTargetBody(String key) {
    final bodyId = _targetBodies[key];
    if (bodyId == null) return null;

    return _physicsEngine.bodies[bodyId];
  }

  /// 액션 이벤트 처리 핵심 메서드
  void _handleActionEvent(ActionEvent event) {
    final actionId = event.actionId;

    // 1. 커스텀 핸들러가 있는지 확인
    if (_actionHandlers.containsKey(actionId)) {
      _actionHandlers[actionId]!(actionId, event, _physicsEngine);
      return;
    }

    // 2. 타겟 바디 매핑 확인
    for (final entry in _targetBodies.entries) {
      final targetKey = entry.key;
      final bodyId = entry.value;

      // 해당 바디의 매핑된 액션 확인
      final bodyActions = _bodyActionMap[bodyId];
      if (bodyActions == null) continue;

      // 매핑된 액션에 현재 이벤트의 액션 ID가 포함되어 있는지 확인
      if (bodyActions.containsValue(actionId)) {
        _applyInputToBody(bodyId, actionId, event);
      }
    }
  }

  /// 특정 바디에 입력 이벤트 적용
  void _applyInputToBody(int bodyId, String actionId, ActionEvent event) {
    final body = _physicsEngine.bodies[bodyId];
    if (body == null) return;

    // 액션 타입과 이벤트 타입에 따라 다른 처리
    switch (event.actionType) {
      case ActionType.button:
        _handleButtonAction(body, actionId, event);
        break;

      case ActionType.continuous:
        _handleContinuousAction(body, actionId, event);
        break;

      case ActionType.vector:
        _handleVectorAction(body, actionId, event);
        break;
    }
  }

  /// 버튼 타입 액션 처리
  void _handleButtonAction(
    PhysicsBody body,
    String actionId,
    ActionEvent event,
  ) {
    // 기본 규칙: 액션 ID로 어떤 종류의 버튼 액션인지 파악
    // 예: "jump" 액션은 위쪽으로 impulse 적용

    if (event.eventType != InputEventType.press) return;

    if (actionId.contains('jump')) {
      // 점프 액션
      body.applyImpulse(Vector2D(0, -10.0 * impulseMultiplier));
    } else if (actionId.contains('boost')) {
      // 부스트 액션 - 현재 방향으로 추가 힘
      final direction = Vector2D.fromAngle(body.rotation, 1.0);
      body.applyForce(direction * 20.0 * forceMultiplier);
    } else if (actionId.contains('brake')) {
      // 제동 액션 - 속도 반대 방향으로 힘
      if (body.velocity.magnitudeSquared > 0.01) {
        final brakeForce = body.velocity.normalized * -10.0 * forceMultiplier;
        body.applyForce(brakeForce);
      }
    }
  }

  /// 연속값 타입 액션 처리
  void _handleContinuousAction(
    PhysicsBody body,
    String actionId,
    ActionEvent event,
  ) {
    final value = event.value ?? 0.0;

    if (actionId.contains('throttle') || actionId.contains('accelerate')) {
      // 가속/감속 액션
      final direction = Vector2D.fromAngle(body.rotation, 1.0);
      body.applyForce(direction * value * forceMultiplier);
    } else if (actionId.contains('rotation') || actionId.contains('steer')) {
      // 회전 액션
      body.torque += value * rotationSensitivity;
    }
  }

  /// 벡터 타입 액션 처리
  void _handleVectorAction(
    PhysicsBody body,
    String actionId,
    ActionEvent event,
  ) {
    final vector = event.vector;
    if (vector == null) return;

    final vx = vector['x'] ?? 0.0;
    final vy = vector['y'] ?? 0.0;

    if (actionId.contains('move') || actionId.contains('direction')) {
      // 이동 액션
      final forceVector =
          Vector2D(vx, vy) * forceMultiplier * movementSensitivity;
      body.applyForce(forceVector);
    } else if (actionId.contains('aim') || actionId.contains('target')) {
      // 조준 액션 - 특정 방향 바라보기
      if (vx.abs() > 0.01 || vy.abs() > 0.01) {
        final targetAngle = math.atan2(vy, vx);
        final angleDiff = targetAngle - body.rotation;

        // 각도 차이 정규화 (-π ~ π)
        var normalizedDiff = angleDiff;
        while (normalizedDiff > math.pi) normalizedDiff -= 2 * math.pi;
        while (normalizedDiff < -math.pi) normalizedDiff += 2 * math.pi;

        // 토크 적용하여 회전
        body.torque += normalizedDiff * rotationSensitivity;
      }
    }
  }

  /// 리소스 해제
  void dispose() {
    _bodyActionMap.clear();
    _actionHandlers.clear();
    _targetBodies.clear();
    _initialized = false;
  }
}

/// 일반적인 게임에서 사용되는 표준 액션 핸들러들
class StandardPhysicsActionHandlers {
  /// 간단한 플레이어 이동 핸들러
  static PhysicsActionHandler playerMovement() {
    return (actionId, event, engine) {
      final player = engine.bodies[1]; // 일반적으로 ID 1을 플레이어 바디로 가정
      if (player == null) return;

      if (actionId == 'move') {
        final vector = event.vector;
        if (vector == null) return;

        final vx = vector['x'] ?? 0.0;
        final vy = vector['y'] ?? 0.0;

        final forceVector = Vector2D(vx, vy) * 5.0; // 기본 힘 계수
        player.applyForce(forceVector);
      }
    };
  }

  /// 포인트 앤 클릭 이동 핸들러
  static PhysicsActionHandler pointAndClickMovement() {
    return (actionId, event, engine) {
      final player = engine.bodies[1]; // 일반적으로 ID 1을 플레이어 바디로 가정
      if (player == null) return;

      if (actionId == 'click' && event.eventType == InputEventType.press) {
        final vector = event.vector;
        if (vector == null) return;

        // 클릭한 위치를 대상으로
        final targetX = vector['x'] ?? 0.0;
        final targetY = vector['y'] ?? 0.0;
        final target = Vector2D(targetX, targetY);

        // 방향 계산
        final direction = (target - player.position).normalized;

        // 거리에 비례한 힘으로 이동
        final distance = (target - player.position).magnitude;
        final forceVector = direction * math.min(distance * 2.0, 20.0);

        player.applyForce(forceVector);
      }
    };
  }

  /// 포인터로 당기는 고무줄 효과 핸들러
  static PhysicsActionHandler slingshot() {
    Vector2D? dragStart;

    return (actionId, event, engine) {
      if (actionId != 'drag') return;

      final player = engine.bodies[1]; // ID 1을 플레이어로 가정
      if (player == null) return;

      switch (event.eventType) {
        case InputEventType.press:
          // 드래그 시작점 저장
          final vector = event.vector;
          if (vector == null) break;

          dragStart = Vector2D(vector['x'] ?? 0.0, vector['y'] ?? 0.0);
          break;

        case InputEventType.release:
          // 드래그 해제 시 고무줄 효과로 힘 적용
          if (dragStart == null) break;

          final vector = event.vector;
          if (vector == null) break;

          final dragEnd = Vector2D(vector['x'] ?? 0.0, vector['y'] ?? 0.0);

          // 당긴 방향의 반대 방향으로 힘 적용
          final force = dragStart! - dragEnd;

          // 당긴 거리에 비례한 힘 적용
          final magnitude = force.magnitude;
          player.applyImpulse(force * math.min(magnitude * 0.1, 20.0));

          dragStart = null;
          break;

        default:
          break;
      }
    };
  }
}
