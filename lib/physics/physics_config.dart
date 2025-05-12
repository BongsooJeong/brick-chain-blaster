import 'dart:convert';
import 'dart:io';
import 'vector2d.dart';

/// 물리 엔진 설정 관리 클래스
class PhysicsConfig {
  /// 중력 벡터
  Vector2D gravity;

  /// 물리 시뮬레이션 시간 간격 (초)
  double fixedTimeStep;

  /// 속도 반복 횟수 (충돌 해결의 정확도)
  int velocityIterations;

  /// 위치 반복 횟수 (물체 간 침투 해결)
  int positionIterations;

  /// 서브스텝 수 (복잡한 시뮬레이션을 위한 단계 분할)
  int substeps;

  /// 휴면 속도 임계값
  double sleepVelocityThreshold;

  /// 휴면 각속도 임계값
  double sleepAngularVelocityThreshold;

  /// 정적 물체 캐싱 최적화 사용 여부
  bool useStaticBodyCaching;

  /// 디버깅 모드 활성화 여부
  bool debugMode;

  /// 멀티스레딩 활성화 여부
  bool useMultithreading;

  /// SIMD 최적화 활성화 여부
  bool useSIMD;

  /// 하드웨어 프로필 (low, medium, high)
  String hardwareProfile;

  /// 생성자
  PhysicsConfig({
    Vector2D? gravity,
    this.fixedTimeStep = 1 / 60,
    this.velocityIterations = 8,
    this.positionIterations = 3,
    this.substeps = 1,
    this.sleepVelocityThreshold = 0.1,
    this.sleepAngularVelocityThreshold = 0.1,
    this.useStaticBodyCaching = true,
    this.debugMode = false,
    this.useMultithreading = false,
    this.useSIMD = false,
    this.hardwareProfile = 'medium',
  }) : gravity = gravity ?? Vector2D(0, 9.8);

  /// 플랫폼 및 하드웨어 특성에 맞게 구성 조정
  void optimizeForPlatform({
    required bool isMobile,
    required bool isWeb,
    required int cpuCores,
    required double deviceMemoryGB,
  }) {
    if (isMobile) {
      // 모바일 최적화
      if (deviceMemoryGB < 2.0) {
        // 저사양 모바일
        hardwareProfile = 'low';
        velocityIterations = 4;
        positionIterations = 2;
        substeps = 1;
        useStaticBodyCaching = true;
        useMultithreading = false;
        useSIMD = false;
      } else if (deviceMemoryGB < 4.0) {
        // 중간 사양 모바일
        hardwareProfile = 'medium';
        velocityIterations = 6;
        positionIterations = 2;
        substeps = 1;
        useStaticBodyCaching = true;
        useMultithreading = cpuCores > 2;
        useSIMD = true;
      } else {
        // 고사양 모바일
        hardwareProfile = 'high';
        velocityIterations = 8;
        positionIterations = 3;
        substeps = 1;
        useStaticBodyCaching = true;
        useMultithreading = cpuCores > 2;
        useSIMD = true;
      }
    } else if (isWeb) {
      // 웹 최적화
      hardwareProfile = 'medium';
      velocityIterations = 6;
      positionIterations = 2;
      substeps = 1;
      useStaticBodyCaching = true;
      useMultithreading = false; // 웹에서는 일반적으로 웹 워커를 사용하지만 이 구현에서는 비활성화
      useSIMD = false; // 웹에서는 SIMD 지원이 제한적임
    } else {
      // 데스크톱 최적화
      if (cpuCores <= 2) {
        hardwareProfile = 'low';
        velocityIterations = 6;
        positionIterations = 2;
        useMultithreading = false;
      } else if (cpuCores <= 4) {
        hardwareProfile = 'medium';
        velocityIterations = 8;
        positionIterations = 3;
        useMultithreading = true;
      } else {
        hardwareProfile = 'high';
        velocityIterations = 10;
        positionIterations = 5;
        substeps = 2;
        useMultithreading = true;
      }

      useStaticBodyCaching = true;
      useSIMD = true;
    }
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'gravity': {'x': gravity.x, 'y': gravity.y},
      'fixedTimeStep': fixedTimeStep,
      'velocityIterations': velocityIterations,
      'positionIterations': positionIterations,
      'substeps': substeps,
      'sleepVelocityThreshold': sleepVelocityThreshold,
      'sleepAngularVelocityThreshold': sleepAngularVelocityThreshold,
      'useStaticBodyCaching': useStaticBodyCaching,
      'debugMode': debugMode,
      'useMultithreading': useMultithreading,
      'useSIMD': useSIMD,
      'hardwareProfile': hardwareProfile,
    };
  }

  /// JSON 역직렬화
  factory PhysicsConfig.fromJson(Map<String, dynamic> json) {
    return PhysicsConfig(
      gravity: Vector2D(
        json['gravity']['x'] as double,
        json['gravity']['y'] as double,
      ),
      fixedTimeStep: json['fixedTimeStep'] as double,
      velocityIterations: json['velocityIterations'] as int,
      positionIterations: json['positionIterations'] as int,
      substeps: json['substeps'] as int,
      sleepVelocityThreshold: json['sleepVelocityThreshold'] as double,
      sleepAngularVelocityThreshold:
          json['sleepAngularVelocityThreshold'] as double,
      useStaticBodyCaching: json['useStaticBodyCaching'] as bool,
      debugMode: json['debugMode'] as bool,
      useMultithreading: json['useMultithreading'] as bool,
      useSIMD: json['useSIMD'] as bool,
      hardwareProfile: json['hardwareProfile'] as String,
    );
  }

  /// 설정 파일 저장
  Future<void> saveToFile(String filePath) async {
    final file = File(filePath);
    await file.writeAsString(jsonEncode(toJson()));
  }

  /// 설정 파일 로드
  static Future<PhysicsConfig> loadFromFile(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PhysicsConfig.fromJson(json);
    }

    // 기본 설정 반환
    return PhysicsConfig();
  }

  /// 낮은 사양 프로필
  static PhysicsConfig lowProfile() {
    return PhysicsConfig(
      velocityIterations: 4,
      positionIterations: 2,
      substeps: 1,
      useStaticBodyCaching: true,
      useMultithreading: false,
      useSIMD: false,
      hardwareProfile: 'low',
    );
  }

  /// 중간 사양 프로필
  static PhysicsConfig mediumProfile() {
    return PhysicsConfig(
      velocityIterations: 6,
      positionIterations: 3,
      substeps: 1,
      useStaticBodyCaching: true,
      useMultithreading: true,
      useSIMD: true,
      hardwareProfile: 'medium',
    );
  }

  /// 높은 사양 프로필
  static PhysicsConfig highProfile() {
    return PhysicsConfig(
      velocityIterations: 10,
      positionIterations: 5,
      substeps: 2,
      useStaticBodyCaching: true,
      useMultithreading: true,
      useSIMD: true,
      hardwareProfile: 'high',
    );
  }
}

/// 입력 구성 관리 클래스
class InputConfig {
  /// 기본 감도
  double sensitivity;

  /// 마우스 감도
  double mouseSensitivity;

  /// 터치 감도
  double touchSensitivity;

  /// 게임패드 감도
  double gamepadSensitivity;

  /// 마우스 Y축 반전 여부
  bool invertMouseY;

  /// 터치 Y축 반전 여부
  bool invertTouchY;

  /// 게임패드 Y축 반전 여부
  bool invertGamepadY;

  /// 데드존 (조이스틱/게임패드)
  double deadzone;

  /// 입력 디바운싱 시간 (밀리초)
  int debounceMs;

  /// 입력 스로틀링 시간 (밀리초)
  int throttleMs;

  /// 기본 중력 축 감지 활성화 (모바일)
  bool enableGyroscope;

  /// 중력 센서 감도
  double gyroscopeSensitivity;

  /// 생성자
  InputConfig({
    this.sensitivity = 1.0,
    this.mouseSensitivity = 1.0,
    this.touchSensitivity = 1.0,
    this.gamepadSensitivity = 1.0,
    this.invertMouseY = false,
    this.invertTouchY = false,
    this.invertGamepadY = false,
    this.deadzone = 0.1,
    this.debounceMs = 0,
    this.throttleMs = 0,
    this.enableGyroscope = false,
    this.gyroscopeSensitivity = 1.0,
  });

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'sensitivity': sensitivity,
      'mouseSensitivity': mouseSensitivity,
      'touchSensitivity': touchSensitivity,
      'gamepadSensitivity': gamepadSensitivity,
      'invertMouseY': invertMouseY,
      'invertTouchY': invertTouchY,
      'invertGamepadY': invertGamepadY,
      'deadzone': deadzone,
      'debounceMs': debounceMs,
      'throttleMs': throttleMs,
      'enableGyroscope': enableGyroscope,
      'gyroscopeSensitivity': gyroscopeSensitivity,
    };
  }

  /// JSON 역직렬화
  factory InputConfig.fromJson(Map<String, dynamic> json) {
    return InputConfig(
      sensitivity: json['sensitivity'] as double? ?? 1.0,
      mouseSensitivity: json['mouseSensitivity'] as double? ?? 1.0,
      touchSensitivity: json['touchSensitivity'] as double? ?? 1.0,
      gamepadSensitivity: json['gamepadSensitivity'] as double? ?? 1.0,
      invertMouseY: json['invertMouseY'] as bool? ?? false,
      invertTouchY: json['invertTouchY'] as bool? ?? false,
      invertGamepadY: json['invertGamepadY'] as bool? ?? false,
      deadzone: json['deadzone'] as double? ?? 0.1,
      debounceMs: json['debounceMs'] as int? ?? 0,
      throttleMs: json['throttleMs'] as int? ?? 0,
      enableGyroscope: json['enableGyroscope'] as bool? ?? false,
      gyroscopeSensitivity: json['gyroscopeSensitivity'] as double? ?? 1.0,
    );
  }

  /// 설정 파일 저장
  Future<void> saveToFile(String filePath) async {
    final file = File(filePath);
    await file.writeAsString(jsonEncode(toJson()));
  }

  /// 설정 파일 로드
  static Future<InputConfig> loadFromFile(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return InputConfig.fromJson(json);
    }

    // 기본 설정 반환
    return InputConfig();
  }

  /// 플랫폼에 최적화된 설정
  static InputConfig forPlatform({
    required bool isMobile,
    required bool isWebMobile,
    required bool hasGamepad,
  }) {
    if (isMobile || isWebMobile) {
      return InputConfig(
        sensitivity: 1.0,
        touchSensitivity: 1.2,
        gamepadSensitivity: 0.8,
        invertTouchY: false,
        deadzone: 0.15,
        debounceMs: 16,
        throttleMs: 0,
        enableGyroscope: true,
        gyroscopeSensitivity: 0.8,
      );
    } else {
      return InputConfig(
        sensitivity: 1.0,
        mouseSensitivity: 1.0,
        gamepadSensitivity: hasGamepad ? 0.8 : 1.0,
        invertMouseY: false,
        invertGamepadY: false,
        deadzone: 0.1,
        debounceMs: 0,
        throttleMs: 0,
        enableGyroscope: false,
      );
    }
  }
}
