import 'dart:async';
import 'package:flutter/material.dart';

import 'input_handler.dart';
import 'input_event.dart';
import 'platform/web_input_handler.dart';
import 'platform/desktop_input_handler.dart';
import 'platform/mobile_input_handler.dart';
import 'platform/gamepad_input_handler.dart' as gamepad;
import 'platform_detector.dart';

/// 입력 핸들러 팩토리
///
/// 현재 플랫폼에 적합한 입력 핸들러를 생성하는 팩토리 클래스.
/// 플랫폼 감지 및 적절한 핸들러 선택을 자동화합니다.
class InputHandlerFactory {
  /// 싱글톤 인스턴스
  static final InputHandlerFactory _instance = InputHandlerFactory._internal();

  /// 플랫폼 감지기
  final PlatformDetector _platformDetector = PlatformDetector();

  /// 팩토리 생성자
  factory InputHandlerFactory() {
    return _instance;
  }

  /// 내부 생성자
  InputHandlerFactory._internal();

  /// 현재 플랫폼에 가장 적합한 모든 핸들러를 포함하는 복합 핸들러 생성
  Future<CompositeInputHandler> createDefaultHandlers({
    Map<String, dynamic>? options,
    GlobalKey? mobileTargetKey,
  }) async {
    final handlers = <InputHandler>[];

    // 플랫폼 유형에 따라 핸들러 생성
    if (_platformDetector.isWeb) {
      // 웹 환경에서는 WebInputHandler가 가장 적합함
      handlers.add(WebInputHandler());

      // 게임패드 지원이 필요한 경우
      if (options?['enableGamepad'] == true) {
        handlers.add(gamepad.GamepadInputHandler());
      }
    } else if (_platformDetector.isMobile) {
      // 모바일 환경에서는 터치 핸들러가 필요함
      final mobileOptions = <String, dynamic>{
        ...?options,
        if (mobileTargetKey != null) 'targetKey': mobileTargetKey,
      };

      handlers.add(MobileInputHandler());
    } else if (_platformDetector.isDesktop) {
      // 데스크탑 환경에서는 키보드/마우스 핸들러가 가장 적합함
      handlers.add(DesktopInputHandler());

      // 게임패드 지원이 필요한 경우
      if (options?['enableGamepad'] == true) {
        handlers.add(gamepad.GamepadInputHandler());
      }
    } else {
      // 알 수 없는 플랫폼인 경우 기본 웹 핸들러 사용
      handlers.add(WebInputHandler());
    }

    // 모든 핸들러를 하나의 복합 핸들러로 묶기
    return CompositeInputHandler('platform_composite', handlers);
  }

  /// 특정 유형의 핸들러 생성
  InputHandler createHandler(
    String handlerType, {
    Map<String, dynamic>? options,
  }) {
    switch (handlerType) {
      case 'web':
        return WebInputHandler();
      case 'desktop':
        return DesktopInputHandler();
      case 'mobile':
        return MobileInputHandler();
      case 'gamepad':
        return gamepad.GamepadInputHandler();
      default:
        throw ArgumentError('Unknown handler type: $handlerType');
    }
  }

  /// 특정 입력 장치 유형을 지원하는 핸들러 생성
  InputHandler createHandlerForDevice(
    InputDeviceType deviceType, {
    Map<String, dynamic>? options,
  }) {
    switch (deviceType) {
      case InputDeviceType.keyboard:
        // 키보드 입력이 지원되는 플랫폼에서는 데스크탑 핸들러가 적합
        return _platformDetector.isWeb
            ? WebInputHandler()
            : DesktopInputHandler();

      case InputDeviceType.mouse:
        // 마우스 입력이 지원되는 플랫폼에서는 데스크탑 핸들러가 적합
        return _platformDetector.isWeb
            ? WebInputHandler()
            : DesktopInputHandler();

      case InputDeviceType.touch:
        // 터치 입력이 지원되는 플랫폼에서는 모바일 핸들러가 적합
        return _platformDetector.isWeb
            ? WebInputHandler()
            : MobileInputHandler();

      case InputDeviceType.gamepad:
        // 게임패드는 전용 핸들러 사용
        return gamepad.GamepadInputHandler();

      default:
        throw ArgumentError('Unsupported device type: $deviceType');
    }
  }

  /// 현재 플랫폼에서 지원되는 입력 장치 목록 가져오기
  Set<InputDeviceType> getSupportedDeviceTypes() {
    final supported = <InputDeviceType>{};

    if (_platformDetector.supportsKeyboardInput) {
      supported.add(InputDeviceType.keyboard);
    }

    if (_platformDetector.supportsMouseInput) {
      supported.add(InputDeviceType.mouse);
    }

    if (_platformDetector.supportsTouchInput) {
      supported.add(InputDeviceType.touch);
    }

    if (_platformDetector.supportsGamepadInput) {
      supported.add(InputDeviceType.gamepad);
    }

    return supported;
  }
}
