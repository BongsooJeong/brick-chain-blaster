import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'input_event.dart';
import 'input_handler.dart';
import 'input_mapping.dart';
import 'input_handler_factory.dart';
import 'platform_detector.dart';

/// 액션 이벤트 - 게임 액션과 관련된 입력 이벤트
class ActionEvent {
  /// 액션 ID
  final String actionId;

  /// 액션 타입
  final ActionType actionType;

  /// 이벤트 타입 (press, release, move 등)
  final InputEventType eventType;

  /// 원본 입력 이벤트
  final InputEvent sourceEvent;

  /// 연속값 (축 또는 값 기반 입력용)
  final double? value;

  /// 벡터값 (2D 위치 기반 입력용)
  final Map<String, double>? vector;

  ActionEvent({
    required this.actionId,
    required this.actionType,
    required this.eventType,
    required this.sourceEvent,
    this.value,
    this.vector,
  });

  @override
  String toString() {
    return 'ActionEvent(actionId: $actionId, actionType: $actionType, eventType: $eventType, '
        'value: $value, vector: $vector)';
  }
}

/// 입력 관리자 - 입력 시스템의 핵심 컴포넌트
class InputManager {
  /// 모든 등록된 입력 핸들러
  final Map<String, InputHandler> _handlers = {};

  /// 입력 매핑 관리자
  final InputMappingManager _mappingManager;

  /// 액션 이벤트 스트림
  final StreamController<ActionEvent> _actionEvents;

  /// 원시 입력 이벤트 스트림
  final StreamController<InputEvent> _rawEvents;

  /// 종합 입력 핸들러
  late CompositeInputHandler _compositeHandler;

  /// 디바운스 타이머
  final Map<String, Timer> _debounceTimers = {};

  /// 스로틀 타이머
  final Map<String, DateTime> _throttleTimes = {};

  /// 현재 활성화된 입력 상태
  final Map<String, bool> _activeInputs = {};

  /// 연속 액션 값
  final Map<String, double> _continuousValues = {};

  /// 벡터 액션 값
  final Map<String, Map<String, double>> _vectorValues = {};

  /// 관리자가 초기화되었는지 여부
  bool _isInitialized = false;

  /// 입력 핸들러 팩토리
  final InputHandlerFactory _handlerFactory = InputHandlerFactory();

  /// 플랫폼 감지기
  final PlatformDetector _platformDetector = PlatformDetector();

  InputManager({required String defaultContextId})
    : _mappingManager = InputMappingManager(defaultContextId: defaultContextId),
      _actionEvents = StreamController<ActionEvent>.broadcast(),
      _rawEvents = StreamController<InputEvent>.broadcast() {
    _compositeHandler = CompositeInputHandler('composite', []);
  }

  /// 액션 이벤트 스트림
  Stream<ActionEvent> get actionEvents => _actionEvents.stream;

  /// 원시 입력 이벤트 스트림
  Stream<InputEvent> get rawEvents => _rawEvents.stream;

  /// 초기화 여부
  bool get isInitialized => _isInitialized;

  /// 입력 핸들러 추가
  void addHandler(InputHandler handler) {
    if (_handlers.containsKey(handler.id)) {
      throw Exception('Handler with ID ${handler.id} already exists');
    }

    _handlers[handler.id] = handler;

    // 종합 핸들러 업데이트
    _compositeHandler = CompositeInputHandler(
      'composite',
      _handlers.values.toList(),
    );
  }

  /// 입력 핸들러 제거
  Future<void> removeHandler(String handlerId) async {
    final handler = _handlers[handlerId];
    if (handler == null) {
      return;
    }

    await handler.dispose();
    _handlers.remove(handlerId);

    // 종합 핸들러 업데이트
    _compositeHandler = CompositeInputHandler(
      'composite',
      _handlers.values.toList(),
    );
  }

  /// 입력 관리자 초기화
  Future<void> initialize({
    Map<String, dynamic>? options,
    GlobalKey? mobileTargetKey,
    Set<String>? handlerTypes,
  }) async {
    if (_isInitialized) {
      return;
    }

    // 핸들러 자동 감지 및 생성
    if (_handlers.isEmpty) {
      if (handlerTypes != null && handlerTypes.isNotEmpty) {
        // 특정 핸들러 유형만 추가
        for (final type in handlerTypes) {
          try {
            final handler = _handlerFactory.createHandler(
              type,
              options: options,
            );
            addHandler(handler);
          } catch (e) {
            print('Failed to create handler for type: $type, error: $e');
          }
        }
      } else {
        // 현재 플랫폼에 맞는 기본 핸들러 자동 생성
        final compositeHandler = await _handlerFactory.createDefaultHandlers(
          options: options,
          mobileTargetKey: mobileTargetKey,
        );

        // 복합 핸들러 대신 개별 핸들러를 직접 추가
        for (final handler in compositeHandler.getHandlers()) {
          addHandler(handler);
        }
      }
    }

    // 종합 핸들러 초기화
    await _compositeHandler.initialize(options);

    // 이벤트 구독
    _compositeHandler.events.listen(_handleRawEvent);

    _isInitialized = true;
  }

  /// 입력 관리자 업데이트 (게임 루프에서 호출)
  void update(double deltaTime) {
    if (!_isInitialized) {
      return;
    }

    _compositeHandler.update(deltaTime);
  }

  /// 일시 중지
  void pause() {
    if (!_isInitialized) {
      return;
    }

    _compositeHandler.pause();
  }

  /// 재개
  void resume() {
    if (!_isInitialized) {
      return;
    }

    _compositeHandler.resume();
  }

  /// 리소스 해제
  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    // 디바운스 타이머 정리
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    // 종합 핸들러 해제
    await _compositeHandler.dispose();

    // 원시 입력 핸들러 해제
    for (final handler in _handlers.values) {
      await handler.dispose();
    }
    _handlers.clear();

    // 스트림 컨트롤러 닫기
    await _actionEvents.close();
    await _rawEvents.close();

    _isInitialized = false;
  }

  /// 입력 매핑 파일 로드
  Future<void> loadMappings(String filePath) async {
    final newManager = await InputMappingManager.loadFromFile(filePath);
    final activeContextId =
        _mappingManager.activeContext?.id ?? newManager.defaultContextId;

    // 매핑 관리자 교체
    _mappingManager.setActiveContext(activeContextId);
  }

  /// 입력 매핑 파일 저장
  Future<void> saveMappings(String filePath) async {
    await _mappingManager.saveToFile(filePath);
  }

  /// 입력 콘텍스트 추가
  void addInputContext(InputContext context) {
    _mappingManager.addContext(context);
  }

  /// 활성 입력 콘텍스트 변경
  void setActiveContext(String contextId) {
    _mappingManager.setActiveContext(contextId);

    // 활성 입력 상태 초기화
    _activeInputs.clear();
    _continuousValues.clear();
    _vectorValues.clear();
  }

  /// 기본 입력 콘텍스트로 복귀
  void resetToDefaultContext() {
    _mappingManager.resetToDefaultContext();

    // 활성 입력 상태 초기화
    _activeInputs.clear();
    _continuousValues.clear();
    _vectorValues.clear();
  }

  /// 지정된 액션의 매핑 가져오기
  List<InputMapping> getMappingsForAction(String actionId) {
    return _mappingManager.getMappingsForAction(actionId);
  }

  /// 액션이 현재 활성화되어 있는지 확인
  bool isActionActive(String actionId) {
    return _activeInputs[actionId] == true;
  }

  /// 액션의 현재 연속 값 가져오기
  double? getContinuousActionValue(String actionId) {
    return _continuousValues[actionId];
  }

  /// 액션의 현재 벡터 값 가져오기
  Map<String, double>? getVectorActionValue(String actionId) {
    return _vectorValues[actionId];
  }

  /// 원시 입력 이벤트 처리
  void _handleRawEvent(InputEvent event) {
    // 원시 이벤트 스트림에 추가
    _rawEvents.add(event);

    // 이벤트에 해당하는 액션 찾기
    final actionId = _mappingManager.getActionFromEvent(event);
    if (actionId == null) {
      return;
    }

    // 액션에 대한 매핑 찾기
    final mappings = _mappingManager.getMappingsForAction(actionId);
    if (mappings.isEmpty) {
      return;
    }

    // 이 이벤트와 관련된 매핑 찾기
    final relevantMapping = mappings.firstWhere(
      (mapping) =>
          mapping.deviceType == event.deviceType &&
          mapping.inputIdentifier == event.identifier,
      orElse: () => mappings.first,
    );

    // 이벤트 타입에 따라 액션 상태 업데이트
    if (event.eventType == InputEventType.press) {
      _activeInputs[actionId] = true;
    } else if (event.eventType == InputEventType.release) {
      _activeInputs[actionId] = false;
    }

    // 액션 이벤트 생성
    ActionEvent? actionEvent;

    switch (relevantMapping.actionType) {
      case ActionType.button:
        actionEvent = ActionEvent(
          actionId: actionId,
          actionType: relevantMapping.actionType,
          eventType: event.eventType,
          sourceEvent: event,
        );
        break;

      case ActionType.continuous:
        double value = 0.0;

        // 연속값 계산 (장치 유형에 따라 다름)
        if (event is GamepadInputEvent) {
          value = event.value;
        } else if (event.eventType == InputEventType.press) {
          value = 1.0;
        } else if (event.eventType == InputEventType.release) {
          value = 0.0;
        }

        // 파라미터를 적용하여 값 변환
        if (relevantMapping.parameters != null) {
          final deadzone =
              relevantMapping.parameters!['deadzone'] as double? ?? 0.0;
          final sensitivity =
              relevantMapping.parameters!['sensitivity'] as double? ?? 1.0;
          final invert =
              relevantMapping.parameters!['invert'] as bool? ?? false;

          // 데드존 적용
          if (value.abs() < deadzone) {
            value = 0.0;
          } else {
            // 데드존 보정 (0-1 범위로 정규화)
            final sign = value > 0 ? 1.0 : -1.0;
            value = sign * (value.abs() - deadzone) / (1.0 - deadzone);
          }

          // 감도 적용
          value *= sensitivity;

          // 반전 적용
          if (invert) {
            value = -value;
          }
        }

        // 값 업데이트
        _continuousValues[actionId] = value;

        actionEvent = ActionEvent(
          actionId: actionId,
          actionType: relevantMapping.actionType,
          eventType: event.eventType,
          sourceEvent: event,
          value: value,
        );
        break;

      case ActionType.vector:
        if (event is PositionalInputEvent) {
          final vector = {'x': event.x, 'y': event.y};

          // 파라미터를 적용하여 벡터 변환
          if (relevantMapping.parameters != null) {
            final sensitivity =
                relevantMapping.parameters!['sensitivity'] as double? ?? 1.0;
            final invertX =
                relevantMapping.parameters!['invertX'] as bool? ?? false;
            final invertY =
                relevantMapping.parameters!['invertY'] as bool? ?? false;

            // 감도 적용
            vector['x'] = vector['x']! * sensitivity;
            vector['y'] = vector['y']! * sensitivity;

            // 반전 적용
            if (invertX) {
              vector['x'] = -vector['x']!;
            }
            if (invertY) {
              vector['y'] = -vector['y']!;
            }
          }

          // 벡터 업데이트
          _vectorValues[actionId] = vector;

          actionEvent = ActionEvent(
            actionId: actionId,
            actionType: relevantMapping.actionType,
            eventType: event.eventType,
            sourceEvent: event,
            vector: vector,
          );
        }
        break;
    }

    if (actionEvent != null) {
      // 디바운싱/스로틀링 적용
      if (relevantMapping.parameters != null) {
        final debounceMs = relevantMapping.parameters!['debounceMs'] as int?;
        final throttleMs = relevantMapping.parameters!['throttleMs'] as int?;

        if (debounceMs != null && debounceMs > 0) {
          _debounceEvent(actionEvent, debounceMs);
          return;
        }

        if (throttleMs != null && throttleMs > 0) {
          if (_throttleEvent(actionEvent, throttleMs)) {
            return;
          }
        }
      }

      // 이벤트 발행
      _actionEvents.add(actionEvent);
    }
  }

  /// 이벤트 디바운싱
  void _debounceEvent(ActionEvent event, int delayMs) {
    final key = '${event.actionId}_${event.eventType}';

    // 이전 타이머가 있으면 취소
    _debounceTimers[key]?.cancel();

    // 새 타이머 설정
    _debounceTimers[key] = Timer(Duration(milliseconds: delayMs), () {
      _actionEvents.add(event);
      _debounceTimers.remove(key);
    });
  }

  /// 이벤트 스로틀링
  bool _throttleEvent(ActionEvent event, int delayMs) {
    final key = '${event.actionId}_${event.eventType}';
    final now = DateTime.now();

    // 마지막 이벤트 시간 확인
    final lastTime = _throttleTimes[key];
    if (lastTime != null) {
      final diff = now.difference(lastTime).inMilliseconds;
      if (diff < delayMs) {
        return true; // 스로틀링 - 이벤트 무시
      }
    }

    // 새 시간 기록
    _throttleTimes[key] = now;
    return false; // 이벤트 허용
  }

  /// 현재 플랫폼에서 지원되는 입력 장치 유형 얻기
  Set<InputDeviceType> getSupportedDeviceTypes() {
    return _handlerFactory.getSupportedDeviceTypes();
  }

  /// 현재 실행 중인 플랫폼 유형 얻기
  PlatformType getPlatformType() {
    return _platformDetector.platformType;
  }

  /// 특정 입력 장치 지원 여부 확인
  bool supportsDeviceType(InputDeviceType deviceType) {
    return getSupportedDeviceTypes().contains(deviceType);
  }
}
