import 'dart:collection';
import 'vector2d.dart';
import 'collision.dart';
import 'physics_body.dart';
import 'dart:math' as math;

/// 물리 엔진 디버깅 정보
class PhysicsDebugInfo {
  /// 물리 시뮬레이션 통계
  final Map<String, double> stats = {};

  /// 충돌 정보
  final List<Collision> collisions = [];

  /// 바디 추적 정보
  final Map<int, List<PhysicsBodyTracking>> bodyTracking = {};

  /// FPS 기록
  final Queue<double> fpsHistory = Queue<double>();

  /// 최대 FPS 기록 유지 수
  final int maxFpsHistory;

  /// 최대 충돌 기록 수
  final int maxCollisionHistory;

  /// 프로파일링 타이머
  final Map<String, double> timers;

  /// 로그 기록
  final Queue<String> logs;

  /// 경고 기록
  final Queue<String> warnings;

  /// 디버그 플래그
  final Map<String, bool> flags;

  /// 최대 로그 크기
  final int maxLogSize;

  PhysicsDebugInfo({
    this.maxFpsHistory = 60,
    this.maxCollisionHistory = 20,
    Map<String, double>? timers,
    Queue<String>? logs,
    Queue<String>? warnings,
    Map<String, bool>? flags,
    this.maxLogSize = 100,
  }) : timers = timers ?? {},
       logs = logs ?? Queue<String>(),
       warnings = warnings ?? Queue<String>(),
       flags = flags ?? {};

  /// FPS 데이터 추가
  void addFpsDataPoint(double fps) {
    fpsHistory.add(fps);

    // 최대 크기 유지
    while (fpsHistory.length > maxFpsHistory) {
      fpsHistory.removeFirst();
    }
  }

  /// 충돌 데이터 추가
  void addCollision(Collision collision) {
    collisions.add(collision);

    // 최대 크기 유지
    while (collisions.length > maxCollisionHistory) {
      collisions.removeAt(0);
    }
  }

  /// 특정 물리 바디 추적 시작
  void trackBody(int bodyId) {
    bodyTracking[bodyId] = [];
  }

  /// 물리 바디 추적 중지
  void stopTrackingBody(int bodyId) {
    bodyTracking.remove(bodyId);
  }

  /// 추적 중인 바디 데이터 기록
  void recordBodyData(int bodyId, PhysicsBody body) {
    if (!bodyTracking.containsKey(bodyId)) {
      return;
    }

    final tracking = bodyTracking[bodyId]!;

    tracking.add(
      PhysicsBodyTracking(
        position: Vector2D.copy(body.position),
        velocity: Vector2D.copy(body.velocity),
        force: Vector2D.copy(body.force),
        rotation: body.rotation,
        angularVelocity: body.angularVelocity,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // 최대 100개 데이터포인트만 유지
    if (tracking.length > 100) {
      tracking.removeAt(0);
    }
  }

  /// 디버그 정보 초기화
  void clear() {
    stats.clear();
    collisions.clear();
    bodyTracking.clear();
    fpsHistory.clear();
    logs.clear();
    warnings.clear();
  }

  /// 통계 항목 기록/업데이트
  void setStat(String name, double value) {
    stats[name] = value;
  }

  /// 통계 항목 증가
  void incrementStat(String name, [double amount = 1.0]) {
    stats[name] = (stats[name] ?? 0) + amount;
  }

  /// 타이머 시작
  void startTimer(String name) {
    timers[name] = DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  /// 타이머 종료 및 시간 기록
  double endTimer(String name) {
    final startTime = timers[name];
    if (startTime == null) {
      return 0;
    }

    final endTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    final duration = endTime - startTime;

    // 타이머 이름에 '_time' 접미사를 붙여 통계에 저장
    stats['${name}_time'] = duration;

    return duration;
  }

  /// 로그 추가
  void log(String message) {
    logs.add('[${DateTime.now()}] $message');

    // 최대 크기 제한
    while (logs.length > maxLogSize) {
      logs.removeFirst();
    }
  }

  /// 경고 추가
  void warn(String message) {
    warnings.add('[${DateTime.now()}] WARNING: $message');

    // 최대 크기 제한
    while (warnings.length > maxLogSize) {
      warnings.removeFirst();
    }
  }

  /// 디버그 플래그 설정
  void setFlag(String name, bool value) {
    flags[name] = value;
  }

  /// 디버그 플래그 확인
  bool checkFlag(String name) {
    return flags[name] ?? false;
  }
}

/// 물리 바디 추적 데이터
class PhysicsBodyTracking {
  final Vector2D position;
  final Vector2D velocity;
  final Vector2D force;
  final double rotation;
  final double angularVelocity;
  final int timestamp;

  PhysicsBodyTracking({
    required this.position,
    required this.velocity,
    required this.force,
    required this.rotation,
    required this.angularVelocity,
    required this.timestamp,
  });
}

/// 물리 엔진 프로파일러 클래스
class PhysicsProfiler {
  /// 디버그 정보 객체
  final PhysicsDebugInfo _debugInfo;

  /// 프로파일링 활성화 여부
  bool enabled;

  /// 프로파일링 샘플 수
  int _sampleCount = 0;

  /// 프로파일링 구간 누적 시간
  final Map<String, double> _accumulatedTimes = {};

  /// 프로파일링 구간 최소/최대 시간
  final Map<String, double> _minTimes = {};
  final Map<String, double> _maxTimes = {};

  /// 생성자
  PhysicsProfiler(this._debugInfo, {this.enabled = true});

  /// 프로파일링 구간 시작
  void begin(String section) {
    if (!enabled) return;

    _debugInfo.startTimer(section);
  }

  /// 프로파일링 구간 종료
  void end(String section) {
    if (!enabled) return;

    final duration = _debugInfo.endTimer(section);

    // 누적 시간 업데이트
    _accumulatedTimes[section] = (_accumulatedTimes[section] ?? 0) + duration;

    // 최소/최대 시간 업데이트
    if (!_minTimes.containsKey(section) || duration < _minTimes[section]!) {
      _minTimes[section] = duration;
    }

    if (!_maxTimes.containsKey(section) || duration > _maxTimes[section]!) {
      _maxTimes[section] = duration;
    }
  }

  /// 프로파일링 리셋
  void reset() {
    _sampleCount = 0;
    _accumulatedTimes.clear();
    _minTimes.clear();
    _maxTimes.clear();
  }

  /// 프로파일링 결과 업데이트
  void update() {
    if (!enabled || _sampleCount == 0) return;

    // 각 섹션의 평균 시간 계산
    for (final section in _accumulatedTimes.keys) {
      final avgTime = _accumulatedTimes[section]! / _sampleCount;
      final minTime = _minTimes[section] ?? 0;
      final maxTime = _maxTimes[section] ?? 0;

      _debugInfo.setStat('${section}_avg_time', avgTime);
      _debugInfo.setStat('${section}_min_time', minTime);
      _debugInfo.setStat('${section}_max_time', maxTime);
    }
  }

  /// 새 프레임 샘플 시작
  void beginFrame() {
    if (!enabled) return;

    _sampleCount++;
    _debugInfo.startTimer('frame');
  }

  /// 프레임 샘플 종료
  void endFrame() {
    if (!enabled) return;

    final frameTime = _debugInfo.endTimer('frame');

    // FPS 계산 (1초 = 1000ms)
    final fps = frameTime > 0 ? 1000.0 / frameTime : 0;
    _debugInfo.setStat('fps', fps);

    // 프레임 시간 통계 업데이트
    _accumulatedTimes['frame'] = (_accumulatedTimes['frame'] ?? 0) + frameTime;

    if (!_minTimes.containsKey('frame') || frameTime < _minTimes['frame']!) {
      _minTimes['frame'] = frameTime;
    }

    if (!_maxTimes.containsKey('frame') || frameTime > _maxTimes['frame']!) {
      _maxTimes['frame'] = frameTime;
    }

    // 초당 프레임 수가 특정 값보다 낮으면 경고
    if (fps < 30) {
      _debugInfo.warn('Low FPS: $fps');
    }
  }

  /// 프로파일링 실행 함수
  T profile<T>(String section, T Function() function) {
    if (!enabled) return function();

    begin(section);
    try {
      return function();
    } finally {
      end(section);
    }
  }

  /// 프로파일링 데이터 문자열 변환
  @override
  String toString() {
    if (!enabled || _sampleCount == 0) {
      return 'Profiling disabled or no samples collected';
    }

    final buffer = StringBuffer('Physics Profiler Report:\n');

    // FPS 정보
    final fps = _debugInfo.stats['fps'] ?? 0;
    buffer.write('FPS: ${fps.toStringAsFixed(1)}\n');

    // 각 섹션의 평균/최소/최대 시간
    buffer.write('Section Times (ms):\n');

    final sortedSections =
        _accumulatedTimes.keys.toList()..sort(
          (a, b) => _accumulatedTimes[b]!.compareTo(_accumulatedTimes[a]!),
        );

    for (final section in sortedSections) {
      final avgTime = _accumulatedTimes[section]! / _sampleCount;
      final minTime = _minTimes[section] ?? 0;
      final maxTime = _maxTimes[section] ?? 0;

      buffer.write(
        '  $section: '
        'Avg=${avgTime.toStringAsFixed(2)}, '
        'Min=${minTime.toStringAsFixed(2)}, '
        'Max=${maxTime.toStringAsFixed(2)}\n',
      );
    }

    return buffer.toString();
  }
}
