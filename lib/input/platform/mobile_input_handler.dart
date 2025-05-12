import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input_event.dart';
import '../input_handler.dart';

/// 모바일 플랫폼 입력 핸들러
/// Flutter 제스처 감지기를 통한 터치 이벤트 처리
class MobileInputHandler implements PositionalInputHandler {
  @override
  final String id = 'mobile_input';

  @override
  final Set<InputDeviceType> supportedDevices = {InputDeviceType.touch};

  @override
  InputHandlerState state = InputHandlerState.uninitialized;

  /// 이벤트 스트림 컨트롤러
  final StreamController<InputEvent> _eventsController =
      StreamController<InputEvent>.broadcast();

  /// 활성화된 터치 포인트
  final Map<int, Map<String, double>> _activeTouches = {};

  /// 제스처 인식기
  GestureRecognizer? _gestureRecognizer;

  /// 화면 크기 정보
  Size? _screenSize;

  /// 타겟 위젯을 위한 글로벌 키
  GlobalKey? _targetKey;

  @override
  Stream<InputEvent> get events => _eventsController.stream;

  @override
  Future<void> initialize([Map<String, dynamic>? options]) async {
    if (state != InputHandlerState.uninitialized) {
      return;
    }

    // 타겟 위젯 키 저장 (제공된 경우)
    if (options != null && options.containsKey('targetKey')) {
      _targetKey = options['targetKey'] as GlobalKey;
    }

    // 화면 크기 정보 설정 (제공된 경우)
    if (options != null && options.containsKey('screenSize')) {
      _screenSize = options['screenSize'] as Size;
    }

    // 터치 제스처 인식기 설정
    _gestureRecognizer =
        PanGestureRecognizer()
          ..onStart = _handleTouchStart
          ..onUpdate = _handleTouchUpdate
          ..onEnd = _handleTouchEnd;

    // 햅틱 피드백 허용 (옵션에서 지정한 경우)
    bool enableHapticFeedback =
        options?['enableHapticFeedback'] as bool? ?? false;
    if (enableHapticFeedback) {
      // 초기화 시 가벼운 햅틱 피드백
      HapticFeedback.lightImpact();
    }

    state = InputHandlerState.active;
  }

  @override
  void update(double deltaTime) {
    // 모바일 핸들러는 이벤트 기반이므로 주기적 업데이트 필요 없음
  }

  @override
  void pause() {
    if (state != InputHandlerState.active) {
      return;
    }
    state = InputHandlerState.paused;
  }

  @override
  void resume() {
    if (state != InputHandlerState.paused) {
      return;
    }
    state = InputHandlerState.active;
  }

  @override
  Future<void> dispose() async {
    if (state == InputHandlerState.disposed) {
      return;
    }

    // 제스처 인식기 해제
    _gestureRecognizer?.dispose();
    _gestureRecognizer = null;

    // 활성 터치 정리
    _activeTouches.clear();

    // 스트림 컨트롤러 닫기
    await _eventsController.close();

    state = InputHandlerState.disposed;
  }

  /// 터치 시작 이벤트 처리
  void _handleTouchStart(DragStartDetails details) {
    if (state != InputHandlerState.active) {
      return;
    }

    // 현재 시간 기준 고유 ID 생성 (Flutter는 포인터 ID를 직접 제공하지 않음)
    final touchId = DateTime.now().microsecondsSinceEpoch % 10000;
    final position = details.localPosition;

    // 터치 정보 저장
    _activeTouches[touchId] = {
      'x': position.dx,
      'y': position.dy,
      'pressure': 1.0, // Flutter는 기본적으로 정확한 압력 정보를 제공하지 않음
    };

    // 입력 이벤트 생성 및 전달
    final event = PositionalInputEvent(
      deviceType: InputDeviceType.touch,
      eventType: InputEventType.press,
      identifier: touchId.toString(),
      x: position.dx,
      y: position.dy,
      data: {
        'pressure': 1.0,
        'normalized': _getNormalizedCoordinates(position),
      },
    );

    _eventsController.add(event);
  }

  /// 터치 업데이트 이벤트 처리
  void _handleTouchUpdate(DragUpdateDetails details) {
    if (state != InputHandlerState.active || _activeTouches.isEmpty) {
      return;
    }

    // 첫 번째 활성 터치 포인트 가져오기 (멀티 터치의 경우 추가 로직 필요)
    final touchId = _activeTouches.keys.first;
    final previousPosition = _activeTouches[touchId]!;
    final position = details.localPosition;

    // 이전 위치 저장 및 현재 위치 업데이트
    final updatedInfo = {
      'prevX': previousPosition['x']!,
      'prevY': previousPosition['y']!,
      'x': position.dx,
      'y': position.dy,
      'pressure': 1.0,
    };
    _activeTouches[touchId] = updatedInfo;

    // 입력 이벤트 생성 및 전달
    final event = PositionalInputEvent(
      deviceType: InputDeviceType.touch,
      eventType: InputEventType.move,
      identifier: touchId.toString(),
      x: position.dx,
      y: position.dy,
      previousX: previousPosition['x'],
      previousY: previousPosition['y'],
      data: {
        'pressure': 1.0,
        'normalized': _getNormalizedCoordinates(position),
      },
    );

    _eventsController.add(event);
  }

  /// 터치 종료 이벤트 처리
  void _handleTouchEnd(DragEndDetails details) {
    if (state != InputHandlerState.active || _activeTouches.isEmpty) {
      return;
    }

    // 첫 번째 활성 터치 포인트 가져오기
    final touchId = _activeTouches.keys.first;
    final position = _activeTouches[touchId]!;

    // 입력 이벤트 생성 및 전달
    final event = PositionalInputEvent(
      deviceType: InputDeviceType.touch,
      eventType: InputEventType.release,
      identifier: touchId.toString(),
      x: position['x']!,
      y: position['y']!,
      data: {
        'normalized': _getNormalizedCoordinates(
          Offset(position['x']!, position['y']!),
        ),
      },
    );

    _eventsController.add(event);

    // 터치 정보 삭제
    _activeTouches.remove(touchId);
  }

  /// 정규화된 좌표 계산 (0.0 ~ 1.0 범위)
  Map<String, double> _getNormalizedCoordinates(Offset position) {
    if (_screenSize == null && _targetKey?.currentContext != null) {
      final RenderBox renderBox =
          _targetKey!.currentContext!.findRenderObject() as RenderBox;
      _screenSize = renderBox.size;
    }

    if (_screenSize != null) {
      return {
        'x': position.dx / _screenSize!.width,
        'y': position.dy / _screenSize!.height,
      };
    }

    // 화면 크기를 알 수 없는 경우 원시 좌표 반환
    return {'x': position.dx, 'y': position.dy};
  }

  @override
  bool supportsDevice(InputDeviceType deviceType) {
    return supportedDevices.contains(deviceType);
  }

  @override
  bool isInputActive(String identifier, [InputDeviceType? deviceType]) {
    if (deviceType != null && !supportsDevice(deviceType)) {
      return false;
    }

    final touchId = int.tryParse(identifier);
    return touchId != null && _activeTouches.containsKey(touchId);
  }

  @override
  Future<Map<String, double>> getCurrentPosition([String? identifier]) async {
    if (identifier != null) {
      final touchId = int.tryParse(identifier);
      if (touchId != null && _activeTouches.containsKey(touchId)) {
        final position = _activeTouches[touchId]!;
        return {'x': position['x']!, 'y': position['y']!};
      }
    } else if (_activeTouches.isNotEmpty) {
      // 식별자가 제공되지 않은 경우 첫 번째 터치 반환
      final position = _activeTouches.values.first;
      return {'x': position['x']!, 'y': position['y']!};
    }

    throw Exception('No active touch with identifier: $identifier');
  }

  @override
  Future<Map<String, double>?> getPreviousPosition([String? identifier]) async {
    if (identifier != null) {
      final touchId = int.tryParse(identifier);
      if (touchId != null && _activeTouches.containsKey(touchId)) {
        final position = _activeTouches[touchId]!;
        if (position.containsKey('prevX') && position.containsKey('prevY')) {
          return {'x': position['prevX']!, 'y': position['prevY']!};
        }
      }
    } else if (_activeTouches.isNotEmpty) {
      // 식별자가 제공되지 않은 경우 첫 번째 터치 반환
      final position = _activeTouches.values.first;
      if (position.containsKey('prevX') && position.containsKey('prevY')) {
        return {'x': position['prevX']!, 'y': position['prevY']!};
      }
    }

    return null;
  }

  @override
  Future<List<String>> getActiveIdentifiers() async {
    return _activeTouches.keys.map((id) => id.toString()).toList();
  }

  /// 햅틱 피드백 트리거 (진동)
  void triggerHapticFeedback(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

/// 햅틱 피드백 유형
enum HapticFeedbackType { light, medium, heavy, selection }
