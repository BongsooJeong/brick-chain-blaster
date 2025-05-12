import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io' show Platform;

/// 스레드 풀 작업 요청 타입 열거형
enum WorkerTaskType {
  vectorBatchOperation,
  collisionBatchDetection,
  forceIntegration,
  custom,
}

/// 스레드 풀에 전송되는 작업 데이터
class WorkerTask {
  final WorkerTaskType type;
  final Map<String, dynamic> data;
  final int taskId;

  const WorkerTask({
    required this.type,
    required this.data,
    required this.taskId,
  });

  Map<String, dynamic> toMap() {
    return {'type': type.index, 'data': data, 'taskId': taskId};
  }

  factory WorkerTask.fromMap(Map<String, dynamic> map) {
    return WorkerTask(
      type: WorkerTaskType.values[map['type']],
      data: map['data'],
      taskId: map['taskId'],
    );
  }
}

/// 스레드 풀 작업 결과
class WorkerResult {
  final int taskId;
  final Map<String, dynamic> result;
  final bool success;
  final String? error;

  const WorkerResult({
    required this.taskId,
    required this.result,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'result': result,
      'success': success,
      'error': error,
    };
  }

  factory WorkerResult.fromMap(Map<String, dynamic> map) {
    return WorkerResult(
      taskId: map['taskId'],
      result: map['result'],
      success: map['success'],
      error: map['error'],
    );
  }
}

/// 워커 Isolate에서 실행되는 진입점 함수
void _workerEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((dynamic message) {
    if (message is! Map<dynamic, dynamic>) return;

    try {
      final task = WorkerTask.fromMap(Map<String, dynamic>.from(message));
      final result = _processTask(task);
      sendPort.send(result.toMap());
    } catch (e) {
      sendPort.send(
        WorkerResult(
          taskId: message['taskId'] ?? -1,
          result: {},
          success: false,
          error: e.toString(),
        ).toMap(),
      );
    }
  });
}

/// 작업 처리 로직
WorkerResult _processTask(WorkerTask task) {
  switch (task.type) {
    case WorkerTaskType.vectorBatchOperation:
      return _processVectorBatchOperation(task);

    case WorkerTaskType.collisionBatchDetection:
      return _processCollisionBatchDetection(task);

    case WorkerTaskType.forceIntegration:
      return _processForceIntegration(task);

    case WorkerTaskType.custom:
      return _processCustomTask(task);

    default:
      return WorkerResult(
        taskId: task.taskId,
        result: {},
        success: false,
        error: 'Unknown task type',
      );
  }
}

/// 벡터 배치 작업 처리
WorkerResult _processVectorBatchOperation(WorkerTask task) {
  final operation = task.data['operation'];

  if (operation == 'add') {
    final List<double> a = task.data['a'];
    final List<double> b = task.data['b'];

    if (a.length != b.length) {
      return WorkerResult(
        taskId: task.taskId,
        result: {},
        success: false,
        error: 'Vector arrays must have the same length',
      );
    }

    final result = List<double>.filled(a.length, 0);
    for (int i = 0; i < a.length; i++) {
      result[i] = a[i] + b[i];
    }

    return WorkerResult(
      taskId: task.taskId,
      result: {'result': result},
      success: true,
    );
  } else if (operation == 'multiply') {
    final List<double> a = task.data['vectors'];
    final double scalar = task.data['scalar'];

    final result = List<double>.filled(a.length, 0);
    for (int i = 0; i < a.length; i++) {
      result[i] = a[i] * scalar;
    }

    return WorkerResult(
      taskId: task.taskId,
      result: {'result': result},
      success: true,
    );
  }

  return WorkerResult(
    taskId: task.taskId,
    result: {},
    success: false,
    error: 'Unknown vector operation',
  );
}

/// 충돌 배치 감지 처리
WorkerResult _processCollisionBatchDetection(WorkerTask task) {
  // 실제 구현에서는 물리 객체 배열에 대한 충돌 감지를 수행합니다.
  // 여기서는 간단한 예시만 제공합니다.
  final collisionResults = <Map<String, dynamic>>[];

  // 더미 결과 반환
  return WorkerResult(
    taskId: task.taskId,
    result: {'collisions': collisionResults},
    success: true,
  );
}

/// 힘 적분 처리
WorkerResult _processForceIntegration(WorkerTask task) {
  // 실제 구현에서는 물리 객체 배열에 대한 힘 적분을 수행합니다.
  // 여기서는 간단한 예시만 제공합니다.

  // 더미 결과 반환
  return WorkerResult(
    taskId: task.taskId,
    result: {'integrated': true},
    success: true,
  );
}

/// 사용자 정의 작업 처리
WorkerResult _processCustomTask(WorkerTask task) {
  final functionName = task.data['function'];

  // 사용자 정의 함수에 따라 처리
  if (functionName == 'custom1') {
    // 사용자 정의 함수 구현
  }

  return WorkerResult(
    taskId: task.taskId,
    result: {'processed': true},
    success: true,
  );
}

/// 물리 엔진 스레드 풀 클래스
class PhysicsThreadPool {
  final int _workerCount;
  final List<Isolate> _workers = [];
  final List<SendPort> _workerPorts = [];
  final Map<int, Completer<WorkerResult>> _tasks = {};
  final ReceivePort _receivePort = ReceivePort();
  int _taskIdCounter = 0;
  bool _initialized = false;

  /// 가용한 워커 수
  int get workerCount => _workerCount;

  /// 초기화 여부
  bool get isInitialized => _initialized;

  PhysicsThreadPool({int? workerCount})
    : _workerCount =
          workerCount ??
          (Platform.isIOS || Platform.isAndroid
              ? 1
              : math.max(1, Platform.numberOfProcessors - 1));

  /// 스레드 풀 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    // 워커 생성 및 메인 스레드 수신 포트 설정
    _receivePort.listen(_handleMessage);

    // 워커 Isolate 생성
    for (int i = 0; i < _workerCount; i++) {
      final completer = Completer<SendPort>();

      final isolate = await Isolate.spawn(
        _workerEntryPoint,
        _receivePort.sendPort,
      );

      _workers.add(isolate);

      // 워커의 SendPort 대기
      final workerPort = await completer.future;
      _workerPorts.add(workerPort);
    }

    _initialized = true;
  }

  /// 메시지 핸들러
  void _handleMessage(dynamic message) {
    if (message is SendPort) {
      // 워커 초기화 응답
      for (final completer in _taskCompleters) {
        if (!completer.isCompleted) {
          completer.complete(message);
          return;
        }
      }
    } else if (message is Map<dynamic, dynamic>) {
      // 작업 결과
      try {
        final result = WorkerResult.fromMap(Map<String, dynamic>.from(message));
        final completer = _tasks.remove(result.taskId);

        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        print('Failed to process worker message: $e');
      }
    }
  }

  // 초기화를 위한 Completer 목록
  final List<Completer<SendPort>> _taskCompleters = [];

  /// 작업 제출
  Future<WorkerResult> submitTask(WorkerTask task) async {
    if (!_initialized) {
      throw StateError('ThreadPool not initialized');
    }

    final taskId = _getNextTaskId();
    final completer = Completer<WorkerResult>();
    _tasks[taskId] = completer;

    // 워커 선택 (간단한 라운드 로빈)
    final workerIndex = taskId % _workerPorts.length;
    final workerPort = _workerPorts[workerIndex];

    // 작업 전송
    final taskMap =
        WorkerTask(type: task.type, data: task.data, taskId: taskId).toMap();

    workerPort.send(taskMap);

    return completer.future;
  }

  /// 배치 작업 제출
  Future<List<WorkerResult>> submitBatch(List<WorkerTask> tasks) async {
    final futures = <Future<WorkerResult>>[];

    for (final task in tasks) {
      futures.add(submitTask(task));
    }

    return Future.wait(futures);
  }

  /// 다음 작업 ID 생성
  int _getNextTaskId() {
    return _taskIdCounter++;
  }

  /// 리소스 해제
  Future<void> dispose() async {
    if (!_initialized) return;

    // 진행 중인 작업 취소
    for (final completer in _tasks.values) {
      if (!completer.isCompleted) {
        completer.completeError('ThreadPool disposed');
      }
    }

    // Isolate 종료
    for (final isolate in _workers) {
      isolate.kill(priority: Isolate.immediate);
    }

    // 수신 포트 닫기
    _receivePort.close();

    _workers.clear();
    _workerPorts.clear();
    _tasks.clear();
    _initialized = false;
  }
}
