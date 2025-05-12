import 'dart:async';
import 'input_event.dart';

/// 입력 핸들러 상태 열거형
enum InputHandlerState {
  /// 초기화되지 않음
  uninitialized,

  /// 초기화됨 / 정상 작동 중
  active,

  /// 일시 중지됨
  paused,

  /// 해제됨
  disposed,
}

/// 입력 핸들러 공통 인터페이스
/// 모든 플랫폼별 입력 핸들러가 구현해야 하는 기본 인터페이스
abstract class InputHandler {
  /// 고유 식별자 (핸들러 유형/이름)
  String get id;

  /// 이 핸들러가 지원하는 입력 장치 유형
  Set<InputDeviceType> get supportedDevices;

  /// 현재 핸들러 상태
  InputHandlerState get state;

  /// 이벤트 스트림 - 입력 이벤트를 구독할 수 있는 스트림 제공
  Stream<InputEvent> get events;

  /// 핸들러 초기화
  ///
  /// [options] - 초기화 옵션 (선택적)
  Future<void> initialize([Map<String, dynamic>? options]);

  /// 핸들러 업데이트 - 폴링 방식 구현에서 필요
  ///
  /// [deltaTime] - 이전 업데이트 이후 경과 시간 (초)
  void update(double deltaTime);

  /// 일시 중지
  void pause();

  /// 일시 중지 해제
  void resume();

  /// 핸들러 해제 - 리소스 정리
  Future<void> dispose();

  /// 이 핸들러가 특정 입력 장치 유형을 지원하는지 확인
  bool supportsDevice(InputDeviceType deviceType);

  /// 특정 입력이 현재 활성화되어 있는지 확인 (키 누름, 버튼 누름 등)
  ///
  /// [identifier] - 입력 식별자
  /// [deviceType] - 입력 장치 타입 (선택적)
  bool isInputActive(String identifier, [InputDeviceType? deviceType]);
}

/// 위치 기반 입력 핸들러 인터페이스 (마우스/터치 등)
abstract class PositionalInputHandler extends InputHandler {
  /// 현재 커서/터치 위치
  Future<Map<String, double>> getCurrentPosition([String? identifier]);

  /// 이전 커서/터치 위치
  Future<Map<String, double>?> getPreviousPosition([String? identifier]);

  /// 현재 활성화된 모든 터치 식별자 목록 (다중 터치용)
  Future<List<String>> getActiveIdentifiers();
}

/// 버튼 기반 입력 핸들러 인터페이스 (키보드/게임패드 등)
abstract class ButtonInputHandler extends InputHandler {
  /// 현재 눌려있는 모든 버튼 식별자 목록
  Future<List<String>> getPressedButtons();

  /// 특정 버튼이 눌려있는지 확인
  Future<bool> isButtonPressed(String identifier);
}

/// 게임패드 입력 핸들러 인터페이스
abstract class GamepadInputHandler extends ButtonInputHandler {
  /// 게임패드 연결 여부 확인
  Future<bool> isConnected([int? gamepadIndex]);

  /// 연결된 모든 게임패드 인덱스 목록
  Future<List<int>> getConnectedGamepads();

  /// 현재 축 값 가져오기
  Future<double> getAxisValue(String axisName, [int? gamepadIndex]);
}

/// 복합 입력 핸들러 - 여러 개의 핸들러를 단일 인터페이스로 묶음
class CompositeInputHandler implements InputHandler {
  final String _id;
  final List<InputHandler> _handlers;
  final StreamController<InputEvent> _eventsController;

  InputHandlerState _state = InputHandlerState.uninitialized;
  final List<StreamSubscription> _subscriptions = [];

  @override
  String get id => _id;

  @override
  InputHandlerState get state => _state;

  @override
  Stream<InputEvent> get events => _eventsController.stream;

  @override
  Set<InputDeviceType> get supportedDevices {
    final devices = <InputDeviceType>{};
    for (final handler in _handlers) {
      devices.addAll(handler.supportedDevices);
    }
    return devices;
  }

  CompositeInputHandler(this._id, this._handlers)
    : _eventsController = StreamController<InputEvent>.broadcast();

  @override
  Future<void> initialize([Map<String, dynamic>? options]) async {
    if (_state != InputHandlerState.uninitialized) {
      return;
    }

    // 모든 하위 핸들러 초기화
    for (final handler in _handlers) {
      await handler.initialize(options);

      // 하위 핸들러 이벤트를 이 핸들러 스트림으로 전달
      _subscriptions.add(
        handler.events.listen((event) {
          if (_state == InputHandlerState.active) {
            _eventsController.add(event);
          }
        }),
      );
    }

    _state = InputHandlerState.active;
  }

  @override
  void update(double deltaTime) {
    if (_state != InputHandlerState.active) {
      return;
    }

    for (final handler in _handlers) {
      handler.update(deltaTime);
    }
  }

  @override
  void pause() {
    if (_state != InputHandlerState.active) {
      return;
    }

    for (final handler in _handlers) {
      handler.pause();
    }

    _state = InputHandlerState.paused;
  }

  @override
  void resume() {
    if (_state != InputHandlerState.paused) {
      return;
    }

    for (final handler in _handlers) {
      handler.resume();
    }

    _state = InputHandlerState.active;
  }

  @override
  Future<void> dispose() async {
    if (_state == InputHandlerState.disposed) {
      return;
    }

    // 모든 구독 취소
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // 모든 하위 핸들러 해제
    for (final handler in _handlers) {
      await handler.dispose();
    }

    // 이벤트 컨트롤러 닫기
    await _eventsController.close();

    _state = InputHandlerState.disposed;
  }

  @override
  bool supportsDevice(InputDeviceType deviceType) {
    for (final handler in _handlers) {
      if (handler.supportsDevice(deviceType)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool isInputActive(String identifier, [InputDeviceType? deviceType]) {
    for (final handler in _handlers) {
      if (deviceType != null && !handler.supportsDevice(deviceType)) {
        continue;
      }

      if (handler.isInputActive(identifier, deviceType)) {
        return true;
      }
    }
    return false;
  }

  /// 특정 입력 장치 타입을 처리하는 핸들러 가져오기
  List<InputHandler> getHandlersForDevice(InputDeviceType deviceType) {
    return _handlers.where((h) => h.supportsDevice(deviceType)).toList();
  }

  /// 특정 타입의 핸들러 가져오기
  T? getHandler<T extends InputHandler>() {
    for (final handler in _handlers) {
      if (handler is T) {
        return handler;
      }
    }
    return null;
  }

  /// 내부 핸들러 목록 반환
  List<InputHandler> getHandlers() {
    return List.unmodifiable(_handlers);
  }
}
