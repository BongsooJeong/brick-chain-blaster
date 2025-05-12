import 'dart:async';
import 'dart:html' as html;

import '../input_event.dart';
import '../input_handler.dart';

/// 웹 플랫폼 입력 핸들러
/// HTML DOM 이벤트를 통합 입력 이벤트로 변환
class WebInputHandler implements InputHandler {
  @override
  final String id = 'web_input';

  @override
  final Set<InputDeviceType> supportedDevices = {
    InputDeviceType.keyboard,
    InputDeviceType.mouse,
    InputDeviceType.touch,
  };

  @override
  InputHandlerState state = InputHandlerState.uninitialized;

  /// 이벤트 스트림 컨트롤러
  final StreamController<InputEvent> _eventsController =
      StreamController<InputEvent>.broadcast();

  /// 이벤트 구독
  final List<StreamSubscription> _subscriptions = [];

  /// 활성화된 입력 (키/버튼)
  final Set<String> _activeInputs = {};

  /// 마우스 정보
  final _mouseInfo = {'x': 0.0, 'y': 0.0, 'prevX': 0.0, 'prevY': 0.0};

  /// 터치 정보
  final Map<int, Map<String, double>> _touchInfo = {};

  /// 이벤트 대상 요소
  html.Element? _targetElement;

  @override
  Stream<InputEvent> get events => _eventsController.stream;

  @override
  Future<void> initialize([Map<String, dynamic>? options]) async {
    if (state != InputHandlerState.uninitialized) {
      return;
    }

    // 대상 요소 (기본값은 document.body)
    _targetElement =
        options?['targetElement'] as html.Element? ?? html.document.body;

    // 키보드 이벤트 구독
    _subscriptions.add(html.document.onKeyDown.listen(_handleKeyDown));

    _subscriptions.add(html.document.onKeyUp.listen(_handleKeyUp));

    // 마우스 이벤트 구독
    _subscriptions.add(_targetElement!.onMouseDown.listen(_handleMouseDown));

    _subscriptions.add(_targetElement!.onMouseUp.listen(_handleMouseUp));

    _subscriptions.add(_targetElement!.onMouseMove.listen(_handleMouseMove));

    _subscriptions.add(_targetElement!.onWheel.listen(_handleMouseWheel));

    // 터치 이벤트 구독
    _subscriptions.add(_targetElement!.onTouchStart.listen(_handleTouchStart));

    _subscriptions.add(_targetElement!.onTouchEnd.listen(_handleTouchEnd));

    _subscriptions.add(_targetElement!.onTouchMove.listen(_handleTouchMove));

    // 컨텍스트 메뉴 방지 (우클릭 메뉴)
    if (options?['preventContextMenu'] == true) {
      _subscriptions.add(
        _targetElement!.onContextMenu.listen((event) {
          event.preventDefault();
        }),
      );
    }

    // 일부 브라우저 제스처 방지 (기본 동작)
    if (options?['preventDefaultEvents'] == true) {
      _subscriptions.add(
        _targetElement!.onTouchStart.listen((event) {
          event.preventDefault();
        }),
      );

      _subscriptions.add(
        _targetElement!.onWheel.listen((event) {
          event.preventDefault();
        }),
      );
    }

    state = InputHandlerState.active;
  }

  @override
  void update(double deltaTime) {
    // 웹 핸들러는 이벤트 기반이므로 polling 업데이트 필요 없음
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

    // 모든 구독 취소
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // 활성 입력 정리
    _activeInputs.clear();
    _touchInfo.clear();

    // 스트림 컨트롤러 닫기
    await _eventsController.close();

    state = InputHandlerState.disposed;
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

    return _activeInputs.contains(identifier);
  }

  /// 키 이벤트를 통합 이벤트로 변환
  InputEvent _createKeyboardInputEvent(
    html.KeyboardEvent event,
    InputEventType eventType,
  ) {
    final keyCode = event.keyCode.toString();
    final key = event.key ?? '';

    return InputEvent(
      deviceType: InputDeviceType.keyboard,
      eventType: eventType,
      identifier: keyCode,
      timestamp: DateTime.now(),
      data: {
        'key': key,
        'keyCode': keyCode,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
        'repeat': event.repeat,
      },
    );
  }

  /// 마우스 이벤트를 통합 이벤트로 변환
  InputEvent _createMouseInputEvent(
    html.MouseEvent event,
    InputEventType eventType,
  ) {
    final button = event.button.toString();

    // 이전 위치 저장
    _mouseInfo['prevX'] = _mouseInfo['x']!;
    _mouseInfo['prevY'] = _mouseInfo['y']!;

    // 현재 위치 업데이트
    _mouseInfo['x'] = event.client.x.toDouble();
    _mouseInfo['y'] = event.client.y.toDouble();

    return InputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: eventType,
      identifier: button,
      timestamp: DateTime.now(),
      data: {
        'button': button,
        'x': _mouseInfo['x'],
        'y': _mouseInfo['y'],
        'deltaX': _mouseInfo['x']! - _mouseInfo['prevX']!,
        'deltaY': _mouseInfo['y']! - _mouseInfo['prevY']!,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
      },
    );
  }

  /// 터치 이벤트를 통합 이벤트로 변환
  InputEvent _createTouchInputEvent(
    html.TouchEvent event,
    InputEventType eventType,
    html.Touch touch,
  ) {
    final touchId = touch.identifier.toString();

    // 터치 정보 관리
    if (eventType == InputEventType.press || eventType == InputEventType.move) {
      final touchData =
          _touchInfo[touch.identifier] ??
          {
            'prevX': touch.client.x.toDouble(),
            'prevY': touch.client.y.toDouble(),
          };

      if (eventType == InputEventType.move &&
          _touchInfo.containsKey(touch.identifier)) {
        touchData['prevX'] = _touchInfo[touch.identifier]!['x']!;
        touchData['prevY'] = _touchInfo[touch.identifier]!['y']!;
      }

      touchData['x'] = touch.client.x.toDouble();
      touchData['y'] = touch.client.y.toDouble();

      _touchInfo[touch.identifier] = touchData;
    } else if (eventType == InputEventType.release) {
      // 터치 해제 시 정보 삭제
      _touchInfo.remove(touch.identifier);
    }

    final touchData =
        _touchInfo[touch.identifier] ??
        {
          'x': touch.client.x.toDouble(),
          'y': touch.client.y.toDouble(),
          'prevX': touch.client.x.toDouble(),
          'prevY': touch.client.y.toDouble(),
        };

    return InputEvent(
      deviceType: InputDeviceType.touch,
      eventType: eventType,
      identifier: touchId,
      timestamp: DateTime.now(),
      data: {
        'touchId': touchId,
        'x': touchData['x'],
        'y': touchData['y'],
        'deltaX': (touchData['x'] ?? 0.0) - (touchData['prevX'] ?? 0.0),
        'deltaY': (touchData['y'] ?? 0.0) - (touchData['prevY'] ?? 0.0),
        'force': touch.force,
        'totalTouches': event.touches.length,
      },
    );
  }

  /// 키 다운 이벤트 처리
  void _handleKeyDown(html.KeyboardEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final keyCode = event.keyCode.toString();
    _activeInputs.add(keyCode);

    final inputEvent = _createKeyboardInputEvent(event, InputEventType.press);

    _eventsController.add(inputEvent);
  }

  /// 키 업 이벤트 처리
  void _handleKeyUp(html.KeyboardEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final keyCode = event.keyCode.toString();
    _activeInputs.remove(keyCode);

    final inputEvent = _createKeyboardInputEvent(event, InputEventType.release);

    _eventsController.add(inputEvent);
  }

  /// 마우스 다운 이벤트 처리
  void _handleMouseDown(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final button = event.button.toString();
    _activeInputs.add('mouse_$button');

    final inputEvent = _createMouseInputEvent(event, InputEventType.press);

    _eventsController.add(inputEvent);
  }

  /// 마우스 업 이벤트 처리
  void _handleMouseUp(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final button = event.button.toString();
    _activeInputs.remove('mouse_$button');

    final inputEvent = _createMouseInputEvent(event, InputEventType.release);

    _eventsController.add(inputEvent);
  }

  /// 마우스 이동 이벤트 처리
  void _handleMouseMove(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final inputEvent = _createMouseInputEvent(event, InputEventType.move);

    _eventsController.add(inputEvent);
  }

  /// 마우스 휠 이벤트 처리
  void _handleMouseWheel(html.WheelEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    // 휠 데이터 정규화
    final deltaX = event.deltaX;
    final deltaY = event.deltaY;
    final deltaZ = event.deltaZ;

    final inputEvent = InputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: InputEventType.scroll,
      identifier: 'wheel',
      timestamp: DateTime.now(),
      data: {
        'deltaX': deltaX,
        'deltaY': deltaY,
        'deltaZ': deltaZ,
        'x': _mouseInfo['x'],
        'y': _mouseInfo['y'],
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 터치 시작 이벤트 처리
  void _handleTouchStart(html.TouchEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    for (final touch in event.changedTouches) {
      final touchId = touch.identifier.toString();
      _activeInputs.add('touch_$touchId');

      final inputEvent = _createTouchInputEvent(
        event,
        InputEventType.press,
        touch,
      );

      _eventsController.add(inputEvent);
    }
  }

  /// 터치 종료 이벤트 처리
  void _handleTouchEnd(html.TouchEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    for (final touch in event.changedTouches) {
      final touchId = touch.identifier.toString();
      _activeInputs.remove('touch_$touchId');

      final inputEvent = _createTouchInputEvent(
        event,
        InputEventType.release,
        touch,
      );

      _eventsController.add(inputEvent);
    }
  }

  /// 터치 이동 이벤트 처리
  void _handleTouchMove(html.TouchEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    for (final touch in event.changedTouches) {
      final inputEvent = _createTouchInputEvent(
        event,
        InputEventType.move,
        touch,
      );

      _eventsController.add(inputEvent);
    }
  }
}
