import 'dart:convert';
import 'dart:io';

import 'input_event.dart';

/// 게임 액션 타입
enum ActionType {
  /// 버튼 타입 액션 (눌렀다 떼는 경우)
  button,

  /// 연속 액션 (값의 범위가 있는 경우, 예: 조이스틱)
  continuous,

  /// 벡터 액션 (2D 위치 값이 있는 경우, 예: 마우스 이동)
  vector,
}

/// 입력 매핑 클래스 - 물리적 입력을 게임 액션으로 매핑
class InputMapping {
  /// 액션 ID (예: "jump", "move_forward")
  final String actionId;

  /// 입력 장치 유형
  final InputDeviceType deviceType;

  /// 입력 식별자 (예: 키 코드, 마우스 버튼 등)
  final String inputIdentifier;

  /// 액션 타입
  final ActionType actionType;

  /// 수정자 키/버튼 (필요한 경우)
  final Map<String, String>? modifiers;

  /// 값 변환 매개변수 (예: 감도, 데드존)
  final Map<String, dynamic>? parameters;

  InputMapping({
    required this.actionId,
    required this.deviceType,
    required this.inputIdentifier,
    required this.actionType,
    this.modifiers,
    this.parameters,
  });

  /// 맵에서 매핑 생성
  factory InputMapping.fromMap(Map<String, dynamic> map) {
    return InputMapping(
      actionId: map['actionId'],
      deviceType: InputDeviceType.values.firstWhere(
        (e) => e.toString() == 'InputDeviceType.${map['deviceType']}',
      ),
      inputIdentifier: map['inputIdentifier'],
      actionType: ActionType.values.firstWhere(
        (e) => e.toString() == 'ActionType.${map['actionType']}',
      ),
      modifiers:
          map['modifiers'] != null
              ? Map<String, String>.from(map['modifiers'])
              : null,
      parameters: map['parameters'],
    );
  }

  /// 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'actionId': actionId,
      'deviceType': deviceType.toString().split('.').last,
      'inputIdentifier': inputIdentifier,
      'actionType': actionType.toString().split('.').last,
      'modifiers': modifiers,
      'parameters': parameters,
    };
  }

  /// JSON 직렬화
  String toJson() => json.encode(toMap());

  /// JSON에서 매핑 생성
  factory InputMapping.fromJson(String source) =>
      InputMapping.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InputMapping(actionId: $actionId, deviceType: $deviceType, '
        'inputIdentifier: $inputIdentifier, actionType: $actionType)';
  }
}

/// 입력 콘텍스트 - 상황별 입력 매핑 세트
class InputContext {
  /// 콘텍스트 ID (예: "gameplay", "menu", "driving")
  final String id;

  /// 콘텍스트 설명
  final String description;

  /// 이 콘텍스트의 입력 매핑 목록
  final List<InputMapping> mappings;

  InputContext({
    required this.id,
    required this.description,
    required this.mappings,
  });

  /// 맵에서 콘텍스트 생성
  factory InputContext.fromMap(Map<String, dynamic> map) {
    return InputContext(
      id: map['id'],
      description: map['description'],
      mappings: List<InputMapping>.from(
        map['mappings']?.map((x) => InputMapping.fromMap(x)) ?? [],
      ),
    );
  }

  /// 맵으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'mappings': mappings.map((x) => x.toMap()).toList(),
    };
  }

  /// JSON 직렬화
  String toJson() => json.encode(toMap());

  /// JSON에서 콘텍스트 생성
  factory InputContext.fromJson(String source) =>
      InputContext.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InputContext(id: $id, description: $description, '
        'mappings: ${mappings.length})';
  }

  /// 특정 액션에 대한 모든 매핑 찾기
  List<InputMapping> getMappingsForAction(String actionId) {
    return mappings.where((mapping) => mapping.actionId == actionId).toList();
  }

  /// 특정 장치 타입에 대한 모든 매핑 찾기
  List<InputMapping> getMappingsForDevice(InputDeviceType deviceType) {
    return mappings
        .where((mapping) => mapping.deviceType == deviceType)
        .toList();
  }

  /// 콘텍스트에 매핑 추가
  void addMapping(InputMapping mapping) {
    mappings.add(mapping);
  }

  /// 콘텍스트에서 매핑 삭제
  void removeMapping(InputMapping mapping) {
    mappings.remove(mapping);
  }

  /// 특정 액션의 모든 매핑 삭제
  void removeAllMappingsForAction(String actionId) {
    mappings.removeWhere((mapping) => mapping.actionId == actionId);
  }
}

/// 입력 매핑 관리자 - 모든 입력 매핑과 콘텍스트 관리
class InputMappingManager {
  /// 모든 입력 콘텍스트
  final Map<String, InputContext> _contexts = {};

  /// 현재 활성 콘텍스트
  String? _activeContextId;

  /// 기본 콘텍스트 ID
  final String defaultContextId;

  InputMappingManager({required this.defaultContextId});

  /// 현재 활성 콘텍스트 가져오기
  InputContext? get activeContext =>
      _activeContextId != null ? _contexts[_activeContextId] : null;

  /// 콘텍스트 추가
  void addContext(InputContext context) {
    _contexts[context.id] = context;

    // 첫 번째 추가된 콘텍스트이고 아직 활성 콘텍스트가 없는 경우
    _activeContextId ??= context.id;
  }

  /// 콘텍스트 가져오기
  InputContext? getContext(String contextId) {
    return _contexts[contextId];
  }

  /// 활성 콘텍스트 변경
  void setActiveContext(String contextId) {
    if (_contexts.containsKey(contextId)) {
      _activeContextId = contextId;
    } else {
      throw Exception('Input context with ID "$contextId" does not exist');
    }
  }

  /// 활성 콘텍스트로 기본 콘텍스트 설정
  void resetToDefaultContext() {
    if (_contexts.containsKey(defaultContextId)) {
      _activeContextId = defaultContextId;
    } else {
      throw Exception(
        'Default input context with ID "$defaultContextId" does not exist',
      );
    }
  }

  /// 콘텍스트 삭제
  void removeContext(String contextId) {
    // 기본 콘텍스트는 삭제 불가
    if (contextId == defaultContextId) {
      throw Exception('Cannot remove the default input context');
    }

    _contexts.remove(contextId);

    // 활성 콘텍스트가 삭제된 경우 기본 콘텍스트로 변경
    if (_activeContextId == contextId) {
      resetToDefaultContext();
    }
  }

  /// 모든 콘텍스트의 맵 가져오기
  Map<String, dynamic> toMap() {
    return {
      'defaultContextId': defaultContextId,
      'activeContextId': _activeContextId,
      'contexts': _contexts.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  /// 맵에서 매핑 관리자 생성
  factory InputMappingManager.fromMap(Map<String, dynamic> map) {
    final manager = InputMappingManager(
      defaultContextId: map['defaultContextId'],
    );

    final contexts = map['contexts'] as Map<String, dynamic>;
    contexts.forEach((key, value) {
      manager.addContext(InputContext.fromMap(value));
    });

    if (map['activeContextId'] != null) {
      manager.setActiveContext(map['activeContextId']);
    }

    return manager;
  }

  /// JSON 직렬화
  String toJson() => json.encode(toMap());

  /// JSON에서 매핑 관리자 생성
  factory InputMappingManager.fromJson(String source) =>
      InputMappingManager.fromMap(json.decode(source));

  /// 파일에서 매핑 로드
  static Future<InputMappingManager> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Input mapping file not found', filePath);
    }

    final content = await file.readAsString();
    return InputMappingManager.fromJson(content);
  }

  /// 파일에 매핑 저장
  Future<void> saveToFile(String filePath) async {
    final file = File(filePath);
    await file.writeAsString(toJson());
  }

  /// 특정 액션 ID에 대한 매핑 가져오기 (현재 활성 콘텍스트에서)
  List<InputMapping> getMappingsForAction(String actionId) {
    if (_activeContextId == null) {
      return [];
    }

    final context = _contexts[_activeContextId];
    if (context == null) {
      return [];
    }

    return context.getMappingsForAction(actionId);
  }

  /// 이벤트가 특정 액션을 트리거하는지 확인
  String? getActionFromEvent(InputEvent event) {
    if (_activeContextId == null) {
      return null;
    }

    final context = _contexts[_activeContextId];
    if (context == null) {
      return null;
    }

    // 이벤트와 일치하는 매핑 찾기
    for (final mapping in context.mappings) {
      if (mapping.deviceType == event.deviceType &&
          mapping.inputIdentifier == event.identifier) {
        // 수정자 키 확인
        if (mapping.modifiers != null && event is KeyboardInputEvent) {
          bool modifiersMatch = true;

          for (final modifierEntry in mapping.modifiers!.entries) {
            final required = modifierEntry.value.toLowerCase() == 'true';
            final actual = event.hasModifier(modifierEntry.key);

            if (required != actual) {
              modifiersMatch = false;
              break;
            }
          }

          if (!modifiersMatch) {
            continue;
          }
        }

        return mapping.actionId;
      }
    }

    return null;
  }
}
