import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 플랫폼 유형 열거형
enum PlatformType {
  /// 웹 브라우저
  web,

  /// 모바일 기기 (Android, iOS)
  mobile,

  /// 데스크탑 (Windows, macOS, Linux)
  desktop,

  /// 미확인 플랫폼
  unknown,
}

/// 플랫폼 감지 유틸리티
///
/// 현재 실행 중인 환경의 플랫폼 유형을 감지하고 관련 정보를 제공합니다.
class PlatformDetector {
  /// 싱글톤 인스턴스
  static final PlatformDetector _instance = PlatformDetector._internal();

  /// 감지된 플랫폼 유형
  PlatformType _platformType = PlatformType.unknown;

  /// 플랫폼 세부 정보
  final Map<String, dynamic> _platformDetails = {};

  /// 팩토리 생성자
  factory PlatformDetector() {
    return _instance;
  }

  /// 내부 생성자
  PlatformDetector._internal() {
    _detectPlatform();
  }

  /// 현재 플랫폼 유형 가져오기
  PlatformType get platformType => _platformType;

  /// 플랫폼 세부 정보 가져오기
  Map<String, dynamic> get platformDetails =>
      Map.unmodifiable(_platformDetails);

  /// 웹 플랫폼인지 확인
  bool get isWeb => _platformType == PlatformType.web;

  /// 모바일 플랫폼인지 확인
  bool get isMobile => _platformType == PlatformType.mobile;

  /// 데스크탑 플랫폼인지 확인
  bool get isDesktop => _platformType == PlatformType.desktop;

  /// 플랫폼 감지 및 세부 정보 수집
  void _detectPlatform() {
    if (kIsWeb) {
      _platformType = PlatformType.web;
      _platformDetails['environment'] = 'browser';
      // 브라우저 타입은 런타임에 js 인터롭으로 감지 가능
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        _platformType = PlatformType.mobile;
        _platformDetails['os'] = Platform.isAndroid ? 'android' : 'ios';
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        _platformType = PlatformType.desktop;
        if (Platform.isWindows) {
          _platformDetails['os'] = 'windows';
        } else if (Platform.isMacOS) {
          _platformDetails['os'] = 'macos';
        } else if (Platform.isLinux) {
          _platformDetails['os'] = 'linux';
        }
      } else {
        _platformType = PlatformType.unknown;
      }
    }
  }

  /// 현재 플랫폼에서 터치 입력이 지원되는지 확인
  bool get supportsTouchInput {
    if (isWeb) {
      // 웹에서는 정확하게 판단하기 어려움, 런타임에 확인 필요
      return true;
    }

    return isMobile ||
        (_platformType == PlatformType.desktop &&
            _platformDetails['os'] == 'windows'); // Windows는 터치 지원 가능
  }

  /// 현재 플랫폼에서 게임패드 입력이 지원되는지 확인
  bool get supportsGamepadInput {
    // 대부분의 브라우저와 데스크탑에서 지원
    return isWeb || isDesktop;
  }

  /// 현재 플랫폼에서 키보드 입력이 지원되는지 확인
  bool get supportsKeyboardInput {
    // 모바일이 아닌 모든 플랫폼에서 지원
    return !isMobile;
  }

  /// 현재 플랫폼에서 마우스 입력이 지원되는지 확인
  bool get supportsMouseInput {
    // 모바일이 아닌 모든 플랫폼에서 지원
    return !isMobile;
  }

  @override
  String toString() {
    return 'PlatformDetector(platformType: $_platformType, details: $_platformDetails)';
  }
}
