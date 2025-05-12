/// 입력 장치 유형 열거형
enum InputDeviceType {
  /// 마우스 입력
  mouse,

  /// 터치 입력
  touch,

  /// 키보드 입력
  keyboard,

  /// 게임패드 입력
  gamepad,
}

/// 입력 이벤트 타입 열거형
enum InputEventType {
  /// 버튼/키 눌림 이벤트
  press,

  /// 버튼/키 뗌 이벤트
  release,

  /// 이동 이벤트 (마우스/터치)
  move,

  /// 드래그 이벤트
  drag,

  /// 스크롤 이벤트
  scroll,

  /// 다중 터치 제스처 이벤트
  gesture,
}

/// 입력 이벤트 기본 클래스
class InputEvent {
  /// 이벤트가 발생한 장치 유형
  final InputDeviceType deviceType;

  /// 이벤트 유형
  final InputEventType eventType;

  /// 이벤트가 발생한 시간 (timestamp)
  final DateTime timestamp;

  /// 이벤트 데이터 (장치별 추가 정보)
  final Map<String, dynamic> data;

  /// 입력 식별자 (키 코드, 마우스 버튼, 터치 ID 등)
  final String identifier;

  /// 기본 생성자
  InputEvent({
    required this.deviceType,
    required this.eventType,
    required this.identifier,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) : timestamp = timestamp ?? DateTime.now(),
       data = data ?? {};

  /// 이 이벤트가 특정 타입인지 확인
  bool isType(InputEventType type) => eventType == type;

  /// 이 이벤트가 특정 장치에서 발생했는지 확인
  bool isFromDevice(InputDeviceType device) => deviceType == device;

  @override
  String toString() =>
      'InputEvent[device: $deviceType, type: $eventType, id: $identifier]';
}

/// 위치 기반 입력 이벤트 (마우스/터치)
class PositionalInputEvent extends InputEvent {
  /// X 좌표
  final double x;

  /// Y 좌표
  final double y;

  /// 이전 X 좌표 (이동 이벤트용)
  final double? previousX;

  /// 이전 Y 좌표 (이동 이벤트용)
  final double? previousY;

  PositionalInputEvent({
    required super.deviceType,
    required super.eventType,
    required super.identifier,
    required this.x,
    required this.y,
    this.previousX,
    this.previousY,
    super.timestamp,
    super.data,
  });

  /// 이동 거리 계산 (이전 위치가 있는 경우)
  double? get deltaX => previousX != null ? x - previousX! : null;
  double? get deltaY => previousY != null ? y - previousY! : null;

  @override
  String toString() =>
      'PositionalInputEvent[device: $deviceType, type: $eventType, id: $identifier, pos: ($x, $y)]';
}

/// 키보드 입력 이벤트
class KeyboardInputEvent extends InputEvent {
  /// 키 코드
  final int keyCode;

  /// 키 라벨 (사람이 읽을 수 있는 형태)
  final String keyLabel;

  /// 수정자 키 상태 (Alt, Ctrl, Shift 등)
  final Map<String, bool> modifiers;

  KeyboardInputEvent({
    required super.eventType,
    required this.keyCode,
    required this.keyLabel,
    Map<String, bool>? modifiers,
    super.timestamp,
    super.data,
  }) : modifiers = modifiers ?? {},
       super(
         deviceType: InputDeviceType.keyboard,
         identifier: keyCode.toString(),
       );

  /// 특정 수정자 키가 눌렸는지 확인
  bool hasModifier(String modifierName) =>
      modifiers[modifierName.toLowerCase()] == true;

  @override
  String toString() =>
      'KeyboardInputEvent[type: $eventType, key: $keyLabel ($keyCode)]';
}

/// 게임패드 입력 이벤트
class GamepadInputEvent extends InputEvent {
  /// 버튼 인덱스 또는 축 식별자
  final String control;

  /// 값 (버튼 눌림 정도 또는 축 위치)
  final double value;

  /// 이전 값 (변화 계산용)
  final double? previousValue;

  GamepadInputEvent({
    required super.eventType,
    required this.control,
    required this.value,
    this.previousValue,
    super.timestamp,
    int? gamepadIndex,
    Map<String, dynamic>? data,
  }) : super(
         deviceType: InputDeviceType.gamepad,
         identifier: control,
         data: data ?? {'gamepadIndex': gamepadIndex ?? 0},
       );

  /// 게임패드 인덱스 (여러 게임패드 지원)
  int get gamepadIndex => data['gamepadIndex'] as int? ?? 0;

  /// 값 변화 계산
  double? get deltaValue =>
      previousValue != null ? value - previousValue! : null;

  @override
  String toString() =>
      'GamepadInputEvent[type: $eventType, control: $control, value: $value]';
}
