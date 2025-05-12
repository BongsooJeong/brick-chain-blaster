import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import '../input_event.dart';
import '../input_handler.dart';

/// 게임패드 입력 핸들러
/// Web Gamepad API를 통한 표준 게임패드 입력 처리
class GamepadInputHandler implements ButtonInputHandler {
  @override
  final String id = 'gamepad_input';

  @override
  final Set<InputDeviceType> supportedDevices = {InputDeviceType.gamepad};

  @override
  InputHandlerState state = InputHandlerState.uninitialized;

  /// 이벤트 스트림 컨트롤러
  final StreamController<InputEvent> _eventsController =
      StreamController<InputEvent>.broadcast();

  @override
  Stream<InputEvent> get events => _eventsController.stream;

  /// 연결된 게임패드 정보 (인덱스 => 게임패드 객체)
  final Map<int, dynamic> _connectedGamepads = {};

  /// 게임패드 상태 스냅샷 (버튼, 축 값 등)
  final Map<int, Map<String, dynamic>> _gamepadStates = {};

  /// 활성화된 버튼 (gamepadIndex_buttonIndex => 누른 시간)
  final Map<String, DateTime> _activeButtons = {};

  /// 데드존 (스틱 움직임 무시 임계값)
  final double _deadzone;

  /// 업데이트 간격 (초)
  final double _updateInterval;

  /// 타이머
  Timer? _updateTimer;

  /// 진동 지원 여부
  bool _vibrationSupported = false;

  /// 생성자
  GamepadInputHandler({double deadzone = 0.1, double updateInterval = 1 / 60})
    : _deadzone = deadzone,
      _updateInterval = updateInterval;

  @override
  Future<void> initialize([Map<String, dynamic>? options]) async {
    if (state != InputHandlerState.uninitialized) {
      return;
    }

    // 게임패드 연결 이벤트 처리
    html.window.addEventListener('gamepadconnected', _handleGamepadConnected);
    html.window.addEventListener(
      'gamepaddisconnected',
      _handleGamepadDisconnected,
    );

    // 진동 지원 여부 확인 (navigator.getGamepads()로 확인 필요)
    _checkVibrationSupport();

    // 이미 연결된 게임패드 찾기
    _scanForGamepads();

    // 정기 업데이트 타이머 설정
    _updateTimer = Timer.periodic(
      Duration(milliseconds: (_updateInterval * 1000).round()),
      (_) => _updateGamepads(),
    );

    state = InputHandlerState.active;
  }

  @override
  void update(double deltaTime) {
    // 타이머를 통해 자동 호출되므로 여기서는 필요 없음
  }

  @override
  void pause() {
    if (state != InputHandlerState.active) {
      return;
    }
    state = InputHandlerState.paused;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void resume() {
    if (state != InputHandlerState.paused) {
      return;
    }
    _updateTimer = Timer.periodic(
      Duration(milliseconds: (_updateInterval * 1000).round()),
      (_) => _updateGamepads(),
    );
    state = InputHandlerState.active;
  }

  @override
  Future<void> dispose() async {
    if (state == InputHandlerState.disposed) {
      return;
    }

    // 이벤트 리스너 제거
    html.window.removeEventListener(
      'gamepadconnected',
      _handleGamepadConnected,
    );
    html.window.removeEventListener(
      'gamepaddisconnected',
      _handleGamepadDisconnected,
    );

    // 타이머 취소
    _updateTimer?.cancel();
    _updateTimer = null;

    // 활성 버튼 정리
    _activeButtons.clear();

    // 게임패드 정보 정리
    _connectedGamepads.clear();
    _gamepadStates.clear();

    // 스트림 컨트롤러 닫기
    await _eventsController.close();

    state = InputHandlerState.disposed;
  }

  /// 게임패드 연결 이벤트 처리
  void _handleGamepadConnected(html.Event event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final gamepadEvent = event as html.GamepadEvent;
    final gamepad = gamepadEvent.gamepad;
    if (gamepad == null) return;

    final index = gamepad.index!;

    // 게임패드 정보 저장
    _connectedGamepads[index] = gamepad;

    // 초기 상태 생성
    _gamepadStates[index] = {
      'buttons': List<double>.filled(gamepad.buttons!.length, 0.0),
      'axes': List<double>.filled(gamepad.axes!.length, 0.0),
      'timestamp': gamepad.timestamp!,
    };

    // 연결 이벤트 발생
    _eventsController.add(
      GamepadInputEvent(
        eventType: InputEventType.press, // 'connected' 대신 press 사용
        control: 'connection',
        value: 1.0,
        gamepadIndex: index,
        data: {
          'id': gamepad.id!,
          'mapping': gamepad.mapping!,
          'buttonCount': gamepad.buttons!.length,
          'axisCount': gamepad.axes!.length,
          'connected': true,
        },
      ),
    );
  }

  /// 게임패드 연결 해제 이벤트 처리
  void _handleGamepadDisconnected(html.Event event) {
    if (state != InputHandlerState.active) {
      return;
    }

    final gamepadEvent = event as html.GamepadEvent;
    final gamepad = gamepadEvent.gamepad;
    if (gamepad == null) return;

    final index = gamepad.index!;

    // 연결 해제 이벤트 발생
    _eventsController.add(
      GamepadInputEvent(
        eventType: InputEventType.release, // 'disconnected' 대신 release 사용
        control: 'connection',
        value: 0.0,
        gamepadIndex: index,
        data: {'id': gamepad.id!, 'connected': false},
      ),
    );

    // 해당 게임패드의 모든 활성 버튼 해제
    final buttonPrefix = '${index}_';
    final activeToClear =
        _activeButtons.keys
            .where((key) => key.startsWith(buttonPrefix))
            .toList();

    for (final key in activeToClear) {
      final buttonIndex = int.parse(key.split('_')[1]);
      _activeButtons.remove(key);

      // 버튼 해제 이벤트 발생
      _eventsController.add(
        GamepadInputEvent(
          eventType: InputEventType.release,
          control: 'button_$buttonIndex',
          value: 0.0,
          gamepadIndex: index,
          data: {'autoReleased': true},
        ),
      );
    }

    // 게임패드 정보 제거
    _connectedGamepads.remove(index);
    _gamepadStates.remove(index);
  }

  /// 게임패드 스캔
  void _scanForGamepads() {
    try {
      // JS 인터롭을 통해 navigator.getGamepads() 호출
      final gamepads = js.context.callMethod('eval', [
        'navigator.getGamepads()',
      ]);

      // null이 아닌 게임패드 처리
      for (var i = 0; i < 4; i++) {
        final gamepad = gamepads[i];
        if (gamepad != null &&
            !(gamepad is js.JsObject && gamepad == js.context['null'])) {
          // 게임패드 정보를 dart 객체로 변환
          final dartGamepad = _convertJsGamepad(gamepad);
          final index = dartGamepad['index'] as int;

          // 게임패드 정보 저장
          _connectedGamepads[index] = gamepad;

          // 초기 상태 생성
          _gamepadStates[index] = {
            'buttons': List<double>.filled(dartGamepad['buttons'].length, 0.0),
            'axes': List<double>.filled(dartGamepad['axes'].length, 0.0),
            'timestamp': dartGamepad['timestamp'] ?? 0,
          };

          // 연결 이벤트 발생
          _eventsController.add(
            GamepadInputEvent(
              eventType: InputEventType.press, // 'connected' 대신 press 사용
              control: 'connection',
              value: 1.0,
              gamepadIndex: index,
              data: {
                'id': dartGamepad['id'],
                'mapping': dartGamepad['mapping'],
                'buttonCount': dartGamepad['buttons'].length,
                'axisCount': dartGamepad['axes'].length,
                'connected': true,
              },
            ),
          );
        }
      }
    } catch (e) {
      print('게임패드 스캔 실패: $e');
    }
  }

  /// JS 게임패드 객체를 Dart 객체로 변환
  Map<String, dynamic> _convertJsGamepad(dynamic jsGamepad) {
    final dartGamepad = <String, dynamic>{};

    try {
      dartGamepad['index'] = jsGamepad['index'] ?? 0;
      dartGamepad['id'] = jsGamepad['id'] ?? 'unknown';
      dartGamepad['mapping'] = jsGamepad['mapping'] ?? 'standard';
      dartGamepad['connected'] = jsGamepad['connected'] ?? false;
      dartGamepad['timestamp'] = jsGamepad['timestamp'] ?? 0;

      // 버튼 정보 변환
      final jsButtons = jsGamepad['buttons'];
      final buttons = <Map<String, dynamic>>[];
      for (var i = 0; i < jsButtons.length; i++) {
        final jsButton = jsButtons[i];
        buttons.add({
          'pressed': jsButton['pressed'] ?? false,
          'touched': jsButton['touched'] ?? false,
          'value': jsButton['value'] ?? 0.0,
        });
      }
      dartGamepad['buttons'] = buttons;

      // 축 정보 변환
      final jsAxes = jsGamepad['axes'];
      final axes = <double>[];
      for (var i = 0; i < jsAxes.length; i++) {
        axes.add(jsAxes[i] ?? 0.0);
      }
      dartGamepad['axes'] = axes;

      return dartGamepad;
    } catch (e) {
      print('게임패드 객체 변환 실패: $e');
      return {
        'index': 0,
        'id': 'unknown',
        'mapping': 'standard',
        'connected': false,
        'timestamp': 0,
        'buttons': <Map<String, dynamic>>[],
        'axes': <double>[],
      };
    }
  }

  /// 게임패드 상태 업데이트
  void _updateGamepads() {
    if (state != InputHandlerState.active) {
      return;
    }

    try {
      // JS 인터롭을 통해 navigator.getGamepads() 호출
      final gamepads = js.context.callMethod('eval', [
        'navigator.getGamepads()',
      ]);

      // null이 아닌 게임패드 처리
      for (var i = 0; i < 4; i++) {
        final gamepad = gamepads[i];
        if (gamepad != null &&
            !(gamepad is js.JsObject && gamepad == js.context['null'])) {
          // 게임패드 정보를 dart 객체로 변환
          final dartGamepad = _convertJsGamepad(gamepad);
          final index = dartGamepad['index'] as int;

          // 이전 상태 가져오기 (없으면 새로 생성)
          if (!_gamepadStates.containsKey(index)) {
            _gamepadStates[index] = {
              'buttons': List<double>.filled(
                dartGamepad['buttons'].length,
                0.0,
              ),
              'axes': List<double>.filled(dartGamepad['axes'].length, 0.0),
              'timestamp': dartGamepad['timestamp'] ?? 0,
            };
          }

          final previousState = _gamepadStates[index]!;

          // 버튼 상태 업데이트
          final buttons = dartGamepad['buttons'] as List<Map<String, dynamic>>;
          for (var btnIdx = 0; btnIdx < buttons.length; btnIdx++) {
            final buttonState = buttons[btnIdx];
            final value = buttonState['value'] as double;
            final pressed = buttonState['pressed'] as bool;

            final previousValue = previousState['buttons']![btnIdx] as double;
            final buttonKey = '${index}_$btnIdx';

            // 버튼 상태 변경 감지
            if (pressed && !_activeButtons.containsKey(buttonKey)) {
              // 버튼 누름
              _activeButtons[buttonKey] = DateTime.now();

              _eventsController.add(
                GamepadInputEvent(
                  eventType: InputEventType.press,
                  control: 'button_$btnIdx',
                  value: value,
                  gamepadIndex: index,
                  data: {'touched': buttonState['touched']},
                ),
              );
            } else if (!pressed && _activeButtons.containsKey(buttonKey)) {
              // 버튼 해제
              _activeButtons.remove(buttonKey);

              _eventsController.add(
                GamepadInputEvent(
                  eventType: InputEventType.release,
                  control: 'button_$btnIdx',
                  value: value,
                  gamepadIndex: index,
                  data: {'touched': buttonState['touched']},
                ),
              );
            } else if (pressed && (value - previousValue).abs() > 0.01) {
              // 값이 변경된 버튼 (아날로그 트리거 등)
              _eventsController.add(
                GamepadInputEvent(
                  eventType: InputEventType.move, // 'valueChanged' 대신 move 사용
                  control: 'button_$btnIdx',
                  value: value,
                  previousValue: previousValue,
                  gamepadIndex: index,
                  data: {'touched': buttonState['touched'], 'pressed': pressed},
                ),
              );
            }

            // 상태 업데이트
            previousState['buttons']![btnIdx] = value;
          }

          // 축 상태 업데이트
          final axes = dartGamepad['axes'] as List<double>;
          for (var axisIdx = 0; axisIdx < axes.length; axisIdx++) {
            final value = axes[axisIdx];
            final previousValue = previousState['axes']![axisIdx] as double;

            // 데드존 적용
            final adjustedValue = value.abs() < _deadzone ? 0.0 : value;

            // 축 값 변경 감지
            if ((adjustedValue - previousValue).abs() > 0.01) {
              _eventsController.add(
                GamepadInputEvent(
                  eventType: InputEventType.move,
                  control: 'axis_$axisIdx',
                  value: adjustedValue,
                  previousValue: previousValue,
                  gamepadIndex: index,
                  data: {},
                ),
              );

              // 상태 업데이트
              previousState['axes']![axisIdx] = adjustedValue;
            }
          }

          // 타임스탬프 업데이트
          previousState['timestamp'] = dartGamepad['timestamp'] ?? 0;
        }
      }
    } catch (e) {
      print('게임패드 업데이트 실패: $e');
    }
  }

  /// 진동 지원 여부 확인
  void _checkVibrationSupport() {
    try {
      _vibrationSupported = js.context.callMethod('eval', [
        '!!(navigator.getGamepads && "vibrationActuator" in navigator.getGamepads()[0])',
      ]);
    } catch (e) {
      _vibrationSupported = false;
    }
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

    return _activeButtons.containsKey(identifier);
  }

  /// 현재 연결된 게임패드 목록 가져오기
  List<int> getConnectedGamepadIndices() {
    return _connectedGamepads.keys.toList();
  }

  /// 특정 게임패드가 연결되어 있는지 확인
  bool isGamepadConnected(int gamepadIndex) {
    return _connectedGamepads.containsKey(gamepadIndex);
  }

  /// 특정 게임패드의 버튼 눌림 상태 확인
  bool isGamepadButtonPressed(int gamepadIndex, int buttonIndex) {
    final buttonKey = '${gamepadIndex}_$buttonIndex';
    return _activeButtons.containsKey(buttonKey);
  }

  /// 특정 게임패드의 버튼 값 가져오기 (아날로그 트리거 등의 경우)
  double getButtonValue(int gamepadIndex, int buttonIndex) {
    if (!_gamepadStates.containsKey(gamepadIndex)) {
      return 0.0;
    }

    final state = _gamepadStates[gamepadIndex]!;
    if (buttonIndex < 0 || buttonIndex >= state['buttons']!.length) {
      return 0.0;
    }

    return state['buttons']![buttonIndex] as double;
  }

  /// 특정 게임패드의 축 값 가져오기
  double getGamepadAxisValue(int gamepadIndex, int axisIndex) {
    if (!_gamepadStates.containsKey(gamepadIndex)) {
      return 0.0;
    }

    final state = _gamepadStates[gamepadIndex]!;
    if (axisIndex < 0 || axisIndex >= state['axes']!.length) {
      return 0.0;
    }

    return state['axes']![axisIndex] as double;
  }

  /// 스틱 값 가져오기 (축 쌍으로 처리)
  Map<String, double> getStickValues(
    int gamepadIndex,
    int hAxisIndex,
    int vAxisIndex,
  ) {
    return {
      'x': getGamepadAxisValue(gamepadIndex, hAxisIndex),
      'y': getGamepadAxisValue(gamepadIndex, vAxisIndex),
    };
  }

  /// 게임패드 진동 (지원되는 경우)
  Future<bool> vibrate(
    int gamepadIndex, {
    double intensity = 1.0,
    int durationMs = 200,
  }) async {
    if (!_vibrationSupported || !_connectedGamepads.containsKey(gamepadIndex)) {
      return false;
    }

    try {
      final gamepad = _connectedGamepads[gamepadIndex];
      final actuator =
          js.JsObject.fromBrowserObject(gamepad)['vibrationActuator'];

      if (actuator == null) {
        return false;
      }

      // 진동 효과 실행
      js.JsObject.fromBrowserObject(actuator).callMethod('playEffect', [
        'dual-rumble',
        js.JsObject.jsify({
          'startDelay': 0,
          'duration': durationMs,
          'weakMagnitude': intensity,
          'strongMagnitude': intensity,
        }),
      ]);

      return true;
    } catch (e) {
      print('게임패드 진동 실패: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getActiveIdentifiers() async {
    return _activeButtons.keys.toList();
  }

  @override
  Future<List<String>> getPressedButtons() async {
    return _activeButtons.keys.toList();
  }

  @override
  Future<bool> isButtonPressed(String identifier) async {
    return _activeButtons.containsKey(identifier);
  }

  /// 특정 게임패드의 모든 버튼 목록 가져오기
  Future<List<String>> getGamepadButtons(int gamepadIndex) async {
    if (!_gamepadStates.containsKey(gamepadIndex)) {
      return [];
    }

    final state = _gamepadStates[gamepadIndex]!;
    final buttons = state['buttons'] as List<dynamic>;

    return List.generate(buttons.length, (index) => '${gamepadIndex}_$index');
  }

  /// 특정 게임패드의 모든 축 값 가져오기
  Future<List<double>> getGamepadAxes(int gamepadIndex) async {
    if (!_gamepadStates.containsKey(gamepadIndex)) {
      return [];
    }

    final state = _gamepadStates[gamepadIndex]!;
    return List<double>.from(state['axes']!);
  }

  /// 게임패드 진동 트리거 (인터페이스 메서드)
  Future<bool> triggerVibration(
    int gamepadIndex,
    double intensity,
    int durationMs,
  ) async {
    return await vibrate(
      gamepadIndex,
      intensity: intensity,
      durationMs: durationMs,
    );
  }

  // 추상 클래스로부터 필요한 추가 메서드 구현
  @override
  Future<bool> isConnected([int? gamepadIndex]) async {
    if (gamepadIndex != null) {
      return isGamepadConnected(gamepadIndex);
    }
    return _connectedGamepads.isNotEmpty;
  }

  @override
  Future<List<int>> getConnectedGamepads() async {
    return getConnectedGamepadIndices();
  }

  @override
  Future<double> getAxisValue(String axisName, [int? gamepadIndex]) async {
    if (gamepadIndex == null && _connectedGamepads.isEmpty) {
      return 0.0;
    }

    final index = gamepadIndex ?? _connectedGamepads.keys.first;

    if (axisName.startsWith('axis_')) {
      final axisIndex = int.tryParse(axisName.substring(5));
      if (axisIndex != null) {
        return getGamepadAxisValue(index, axisIndex);
      }
    }

    return 0.0;
  }
}
