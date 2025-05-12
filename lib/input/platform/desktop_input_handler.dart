import 'dart:async';
import 'dart:html' as html;

import '../input_event.dart';
import '../input_handler.dart';

/// 데스크탑 플랫폼 입력 핸들러
/// HTML DOM 이벤트를 통한 키보드 및 마우스 입력 처리 (데스크탑 브라우저 최적화)
class DesktopInputHandler
    implements ButtonInputHandler, PositionalInputHandler {
  @override
  final String id = 'desktop_input';

  @override
  final Set<InputDeviceType> supportedDevices = {
    InputDeviceType.keyboard,
    InputDeviceType.mouse,
  };

  @override
  InputHandlerState state = InputHandlerState.uninitialized;

  /// 이벤트 스트림 컨트롤러
  final StreamController<InputEvent> _eventsController =
      StreamController<InputEvent>.broadcast();

  /// 이벤트 구독
  final List<StreamSubscription> _subscriptions = [];

  /// 활성화된 키 (키 코드 => 누른 시간)
  final Map<String, DateTime> _activeKeys = {};

  /// 활성화된 마우스 버튼 (버튼 => 누른 시간)
  final Map<String, DateTime> _activeMouseButtons = {};

  /// 마우스 정보
  final _mouseInfo = {
    'x': 0.0,
    'y': 0.0,
    'prevX': 0.0,
    'prevY': 0.0,
    'screenX': 0.0,
    'screenY': 0.0,
  };

  /// 이벤트 대상 요소
  html.Element? _targetElement;

  /// 키 반복 방지 (밀리초)
  final int _keyRepeatDelay;

  /// 수정자 키 상태
  final Map<String, bool> _modifiers = {
    'shift': false,
    'ctrl': false,
    'alt': false,
    'meta': false,
  };

  @override
  Stream<InputEvent> get events => _eventsController.stream;

  /// 생성자
  DesktopInputHandler({int keyRepeatDelay = 150})
    : _keyRepeatDelay = keyRepeatDelay;

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

    // 컨텍스트 메뉴 방지 (우클릭 메뉴)
    if (options?['preventContextMenu'] == true) {
      _subscriptions.add(
        _targetElement!.onContextMenu.listen((event) => event.preventDefault()),
      );
    }

    // 브라우저 기본 단축키 방지 (F5, Ctrl+R 등)
    if (options?['preventDefaultKeys'] == true) {
      _subscriptions.add(
        html.document.onKeyDown.listen((event) {
          // 특정 키 코드에 대한 기본 동작 방지
          final preventDefaultKeys = [
            116, // F5
            123, // F12
          ];

          if (preventDefaultKeys.contains(event.keyCode) ||
              (event.ctrlKey && event.keyCode == 82)) {
            // Ctrl+R
            event.preventDefault();
          }
        }),
      );
    }

    // 포커스 관리
    if (options?['autoFocus'] == true) {
      _targetElement!.focus();
    }

    // 포커스 이벤트 관리
    _subscriptions.add(html.window.onBlur.listen((_) => _handleWindowBlur()));

    state = InputHandlerState.active;
  }

  @override
  void update(double deltaTime) {
    // 데스크탑 핸들러는 이벤트 기반이므로 업데이트 필요 없음
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
    _activeKeys.clear();
    _activeMouseButtons.clear();

    // 스트림 컨트롤러 닫기
    await _eventsController.close();

    state = InputHandlerState.disposed;
  }

  /// 키 다운 이벤트 처리
  void _handleKeyDown(html.KeyboardEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final keyCode = event.keyCode.toString();
    final key = event.key ?? '';

    // 키 반복 방지 (연속 키 입력 속도 제한)
    if (_activeKeys.containsKey(keyCode)) {
      final lastPress = _activeKeys[keyCode]!;
      final now = DateTime.now();
      if (now.difference(lastPress).inMilliseconds < _keyRepeatDelay) {
        return;
      }
    }

    // 수정자 키 상태 업데이트
    _updateModifiers(event);

    // 키 활성 상태 업데이트
    _activeKeys[keyCode] = DateTime.now();

    // 입력 이벤트 생성 및 전달
    final inputEvent = KeyboardInputEvent(
      eventType: InputEventType.press,
      keyCode: event.keyCode,
      keyLabel: key,
      modifiers: Map.from(_modifiers),
      data: {
        'repeat': event.repeat,
        'location': event.location,
        'code': event.code,
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 키 업 이벤트 처리
  void _handleKeyUp(html.KeyboardEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final keyCode = event.keyCode.toString();
    final key = event.key ?? '';

    // 수정자 키 상태 업데이트
    _updateModifiers(event);

    // 키 활성 상태 업데이트
    _activeKeys.remove(keyCode);

    // 입력 이벤트 생성 및 전달
    final inputEvent = KeyboardInputEvent(
      eventType: InputEventType.release,
      keyCode: event.keyCode,
      keyLabel: key,
      modifiers: Map.from(_modifiers),
    );

    _eventsController.add(inputEvent);
  }

  /// 수정자 키 상태 업데이트
  void _updateModifiers(html.KeyboardEvent event) {
    _modifiers['shift'] = event.shiftKey;
    _modifiers['ctrl'] = event.ctrlKey;
    _modifiers['alt'] = event.altKey;
    _modifiers['meta'] = event.metaKey;
  }

  /// 마우스 다운 이벤트 처리
  void _handleMouseDown(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final button = event.button.toString();

    // 이전 위치 저장
    _mouseInfo['prevX'] = _mouseInfo['x']!;
    _mouseInfo['prevY'] = _mouseInfo['y']!;

    // 현재 위치 업데이트
    _updateMousePosition(event);

    // 버튼 활성 상태 업데이트
    _activeMouseButtons[button] = DateTime.now();

    // 입력 이벤트 생성 및 전달
    final inputEvent = PositionalInputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: InputEventType.press,
      identifier: button,
      x: _mouseInfo['x']!,
      y: _mouseInfo['y']!,
      data: {
        'button': button,
        'buttons': event.buttons,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
        'screenX': _mouseInfo['screenX'],
        'screenY': _mouseInfo['screenY'],
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 마우스 업 이벤트 처리
  void _handleMouseUp(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final button = event.button.toString();

    // 이전 위치 저장
    _mouseInfo['prevX'] = _mouseInfo['x']!;
    _mouseInfo['prevY'] = _mouseInfo['y']!;

    // 현재 위치 업데이트
    _updateMousePosition(event);

    // 버튼 활성 상태 업데이트
    _activeMouseButtons.remove(button);

    // 입력 이벤트 생성 및 전달
    final inputEvent = PositionalInputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: InputEventType.release,
      identifier: button,
      x: _mouseInfo['x']!,
      y: _mouseInfo['y']!,
      previousX: _mouseInfo['prevX'],
      previousY: _mouseInfo['prevY'],
      data: {
        'button': button,
        'buttons': event.buttons,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
        'screenX': _mouseInfo['screenX'],
        'screenY': _mouseInfo['screenY'],
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 마우스 이동 이벤트 처리
  void _handleMouseMove(html.MouseEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    // 이전 위치 저장
    _mouseInfo['prevX'] = _mouseInfo['x']!;
    _mouseInfo['prevY'] = _mouseInfo['y']!;

    // 현재 위치 업데이트
    _updateMousePosition(event);

    // 입력 이벤트 생성 및 전달
    final inputEvent = PositionalInputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: InputEventType.move,
      identifier: 'mouse',
      x: _mouseInfo['x']!,
      y: _mouseInfo['y']!,
      previousX: _mouseInfo['prevX'],
      previousY: _mouseInfo['prevY'],
      data: {
        'buttons': event.buttons,
        'deltaX': _mouseInfo['x']! - _mouseInfo['prevX']!,
        'deltaY': _mouseInfo['y']! - _mouseInfo['prevY']!,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
        'screenX': _mouseInfo['screenX'],
        'screenY': _mouseInfo['screenY'],
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 마우스 휠 이벤트 처리
  void _handleMouseWheel(html.WheelEvent event) {
    if (state != InputHandlerState.active) {
      return;
    }

    // 현재 위치 업데이트
    _updateMousePosition(event);

    // 입력 이벤트 생성 및 전달
    final inputEvent = PositionalInputEvent(
      deviceType: InputDeviceType.mouse,
      eventType: InputEventType.scroll,
      identifier: 'wheel',
      x: _mouseInfo['x']!,
      y: _mouseInfo['y']!,
      data: {
        'deltaX': event.deltaX,
        'deltaY': event.deltaY,
        'deltaZ': event.deltaZ,
        'deltaMode': event.deltaMode,
        'shiftKey': event.shiftKey,
        'ctrlKey': event.ctrlKey,
        'altKey': event.altKey,
        'metaKey': event.metaKey,
      },
    );

    _eventsController.add(inputEvent);
  }

  /// 윈도우 포커스 상실 처리
  void _handleWindowBlur() {
    if (state != InputHandlerState.active) {
      return;
    }

    // 모든 활성 키 해제
    final activeKeysCopy = Map<String, DateTime>.from(_activeKeys);
    for (final keyCode in activeKeysCopy.keys) {
      // 키 업 이벤트 발생
      final inputEvent = KeyboardInputEvent(
        eventType: InputEventType.release,
        keyCode: int.parse(keyCode),
        keyLabel: keyCode,
        modifiers: Map.from(_modifiers),
        data: {'autoReleased': true},
      );
      _eventsController.add(inputEvent);
    }
    _activeKeys.clear();

    // 모든 활성 마우스 버튼 해제
    final activeButtonsCopy = Map<String, DateTime>.from(_activeMouseButtons);
    for (final button in activeButtonsCopy.keys) {
      // 마우스 업 이벤트 발생
      final inputEvent = PositionalInputEvent(
        deviceType: InputDeviceType.mouse,
        eventType: InputEventType.release,
        identifier: button,
        x: _mouseInfo['x']!,
        y: _mouseInfo['y']!,
        data: {'button': button, 'autoReleased': true},
      );
      _eventsController.add(inputEvent);
    }
    _activeMouseButtons.clear();

    // 수정자 키 초기화
    _modifiers['shift'] = false;
    _modifiers['ctrl'] = false;
    _modifiers['alt'] = false;
    _modifiers['meta'] = false;
  }

  /// 마우스 위치 업데이트
  void _updateMousePosition(html.MouseEvent event) {
    // 스크린 좌표 (브라우저 창 기준)
    _mouseInfo['screenX'] = event.screen.x.toDouble();
    _mouseInfo['screenY'] = event.screen.y.toDouble();

    // 클라이언트 좌표 (뷰포트 기준)
    _mouseInfo['x'] = event.client.x.toDouble();
    _mouseInfo['y'] = event.client.y.toDouble();
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

    switch (deviceType) {
      case InputDeviceType.keyboard:
        return _activeKeys.containsKey(identifier);
      case InputDeviceType.mouse:
        return _activeMouseButtons.containsKey(identifier);
      default:
        return _activeKeys.containsKey(identifier) ||
            _activeMouseButtons.containsKey(identifier);
    }
  }

  @override
  Future<Map<String, double>> getCurrentPosition([String? identifier]) async {
    // 마우스 위치 반환
    return {'x': _mouseInfo['x']!, 'y': _mouseInfo['y']!};
  }

  @override
  Future<Map<String, double>?> getPreviousPosition([String? identifier]) async {
    // 이전 마우스 위치 반환
    return {'x': _mouseInfo['prevX']!, 'y': _mouseInfo['prevY']!};
  }

  @override
  Future<List<String>> getActiveIdentifiers() async {
    return _activeMouseButtons.keys.toList();
  }

  @override
  Future<List<String>> getPressedButtons() async {
    return _activeKeys.keys.toList();
  }

  @override
  Future<bool> isButtonPressed(String identifier) async {
    return _activeKeys.containsKey(identifier);
  }

  /// 특정 수정자 키가 눌려있는지 확인
  bool isModifierActive(String modifierName) {
    return _modifiers[modifierName.toLowerCase()] == true;
  }

  /// 현재 모든 수정자 키 상태 가져오기
  Map<String, bool> getModifiers() {
    return Map.from(_modifiers);
  }
}
