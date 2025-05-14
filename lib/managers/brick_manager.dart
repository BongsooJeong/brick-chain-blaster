import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:brick_chain_blaster/components/brick.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 벽돌 패턴 클래스 - 패턴 정의 및 생성 로직
class BrickPattern {
  /// 패턴 배열 (0 = 빈 공간, 1-9 = 벽돌 HP)
  final List<List<int>> layout;

  /// HP 배율 (웨이브 기본 HP에 적용되는 곱셈 계수)
  final double hpMultiplier;

  /// 패턴 이름 (디버깅 및 선택용)
  final String name;

  /// 패턴 설명
  final String description;

  /// 생성자
  const BrickPattern({
    required this.layout,
    this.hpMultiplier = 1.0,
    required this.name,
    this.description = '',
  });

  /// 패턴에서 벽돌 객체 생성
  List<Brick> generateBricks({
    required int waveIndex,
    required double brickWidth,
    required double brickHeight,
    required Vector2 startPosition,
    bool applyRandomization = true,
  }) {
    final bricks = <Brick>[];
    final baseHP = _calculateBaseHP(waveIndex);

    // 패턴 중앙 정렬을 위한 계산
    final patternWidth = layout[0].length;
    final patternHeight = layout.length;

    // 변형 옵션 적용 (웨이브 인덱스가 높을수록 변형 가능성 증가)
    bool flipHorizontal =
        applyRandomization &&
        math.Random().nextDouble() < 0.3 + (waveIndex * 0.05).clamp(0.0, 0.3);
    bool flipVertical =
        applyRandomization &&
        math.Random().nextDouble() < 0.2 + (waveIndex * 0.03).clamp(0.0, 0.2);

    // 패턴 배열 탐색
    for (int y = 0; y < layout.length; y++) {
      for (int x = 0; x < layout[y].length; x++) {
        // 빈 공간이 아닌 경우 벽돌 생성
        if (layout[y][x] > 0) {
          // 변형 적용
          int effectiveX = flipHorizontal ? patternWidth - 1 - x : x;
          int effectiveY = flipVertical ? patternHeight - 1 - y : y;

          // 벽돌 HP 계산 (패턴 값 * 웨이브 기반 기본 HP * 패턴별 배율)
          int brickHP =
              (baseHP * layout[effectiveY][effectiveX] * hpMultiplier).round();
          brickHP = math.max(1, brickHP); // 최소 1 HP 보장

          // 벽돌 타입 결정
          BrickType brickType = _determineBrickType(brickHP, waveIndex);

          // 위치 계산
          final position = Vector2(
            startPosition.x + effectiveX * brickWidth,
            startPosition.y + effectiveY * brickHeight,
          );

          // 벽돌 크기 (표준 크기보다 약간 작게 -> 여백 생성)
          final size = Vector2(brickWidth * 0.9, brickHeight * 0.9);

          // 벽돌 생성 및 추가
          bricks.add(
            Brick(position: position, size: size, hp: brickHP, type: brickType),
          );
        }
      }
    }

    return bricks;
  }

  /// 웨이브 인덱스에 따른 기본 HP 계산
  int _calculateBaseHP(int waveIndex) {
    // 0파는 특수 처리 (튜토리얼 레벨)
    if (waveIndex <= 0) return 1;

    // 로그 함수로 점진적 증가 (1 -> 2 -> 3 -> 3 -> 4 -> 4 -> 4 -> 5 -> 5 -> ...)
    return math.max(1, (math.log(waveIndex + 1) * 1.5).round());
  }

  /// 벽돌 타입 결정 (HP와 웨이브 인덱스 기반)
  BrickType _determineBrickType(int hp, int waveIndex) {
    // 보스 벽돌 (높은 웨이브에서 낮은 확률로 등장)
    if (waveIndex > 5 &&
        hp > 5 &&
        math.Random().nextDouble() < 0.05 + (waveIndex * 0.01)) {
      return BrickType.boss;
    }

    // 특수 벽돌 (중간 웨이브부터 낮은 확률로 등장)
    if (waveIndex > 3 &&
        math.Random().nextDouble() < 0.1 + (waveIndex * 0.02)) {
      return BrickType.special;
    }

    // 강화 벽돌 (HP 3 이상인 경우)
    if (hp >= 3) {
      return BrickType.reinforced;
    }

    // 기본 벽돌
    return BrickType.normal;
  }
}

/// 벽돌 관리자 클래스 - 벽돌 패턴 선택 및 생성 관리
class BrickManager extends Component with HasGameRef<BrickChainGame> {
  /// 현재 웨이브 번호
  int currentWave = 0;

  /// 현재 필드에 있는 벽돌 수
  int get brickCount => _bricks.length;

  /// 벽돌 객체 목록
  final List<Brick> _bricks = [];

  /// 벽돌 객체 목록 불변 복사본 반환
  List<Brick> get activeBricks => List.unmodifiable(_bricks);

  /// 패턴 라이브러리
  final List<BrickPattern> _patterns = [];

  /// 랜덤 생성기
  final _random = math.Random();

  /// 벽돌 기본 크기
  final double brickWidth = 1.5;
  final double brickHeight = 0.6;

  /// 마지막으로 사용된 패턴 인덱스
  int _lastPatternIndex = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 패턴 라이브러리 초기화
    _initializePatternLibrary();

    print('BrickManager 초기화 완료: ${_patterns.length}개 패턴 로드됨');
  }

  /// 패턴 라이브러리 초기화 - 다양한 미리 정의된 패턴 추가
  void _initializePatternLibrary() {
    // 패턴 1: 기본 벽돌 라인 (튜토리얼/시작용)
    _patterns.add(
      BrickPattern(
        name: 'Basic Line',
        description: '기본 라인 패턴 - 초보자용',
        layout: [
          [1, 1, 1, 1, 1],
        ],
        hpMultiplier: 1.0,
      ),
    );

    // 패턴 2: 그리드 패턴
    _patterns.add(
      BrickPattern(
        name: 'Simple Grid',
        description: '간단한 격자 패턴',
        layout: [
          [1, 1, 1, 1, 1],
          [1, 0, 1, 0, 1],
          [1, 1, 1, 1, 1],
        ],
        hpMultiplier: 1.0,
      ),
    );

    // 패턴 3: 피라미드
    _patterns.add(
      BrickPattern(
        name: 'Pyramid',
        description: '피라미드 형태 패턴',
        layout: [
          [0, 0, 2, 0, 0],
          [0, 1, 2, 1, 0],
          [1, 1, 3, 1, 1],
        ],
        hpMultiplier: 1.0,
      ),
    );

    // 패턴 4: 지그재그
    _patterns.add(
      BrickPattern(
        name: 'Zigzag',
        description: '지그재그 패턴',
        layout: [
          [1, 0, 0, 0, 1],
          [0, 2, 0, 2, 0],
          [0, 0, 2, 0, 0],
          [0, 2, 0, 2, 0],
          [1, 0, 0, 0, 1],
        ],
        hpMultiplier: 1.1,
      ),
    );

    // 패턴 5: 요새
    _patterns.add(
      BrickPattern(
        name: 'Fortress',
        description: '요새 형태 패턴',
        layout: [
          [2, 2, 3, 2, 2],
          [2, 0, 0, 0, 2],
          [3, 0, 0, 0, 3],
          [2, 0, 0, 0, 2],
          [2, 2, 2, 2, 2],
        ],
        hpMultiplier: 1.2,
      ),
    );

    // 패턴 6: X 모양
    _patterns.add(
      BrickPattern(
        name: 'X Pattern',
        description: 'X 모양 패턴',
        layout: [
          [2, 0, 0, 0, 2],
          [0, 2, 0, 2, 0],
          [0, 0, 3, 0, 0],
          [0, 2, 0, 2, 0],
          [2, 0, 0, 0, 2],
        ],
        hpMultiplier: 1.2,
      ),
    );

    // 패턴 7: 아치
    _patterns.add(
      BrickPattern(
        name: 'Arch',
        description: '아치 모양 패턴',
        layout: [
          [2, 2, 3, 2, 2],
          [2, 0, 0, 0, 2],
          [2, 0, 0, 0, 2],
          [0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0],
        ],
        hpMultiplier: 1.1,
      ),
    );

    // 패턴 8: 대각선 삼각형
    _patterns.add(
      BrickPattern(
        name: 'Diagonal Triangle',
        description: '대각선 삼각형 패턴',
        layout: [
          [0, 0, 0, 0, 3],
          [0, 0, 0, 2, 2],
          [0, 0, 2, 2, 0],
          [0, 2, 2, 0, 0],
          [3, 2, 0, 0, 0],
        ],
        hpMultiplier: 1.2,
      ),
    );

    // 패턴 9: 강화된 중앙
    _patterns.add(
      BrickPattern(
        name: 'Reinforced Center',
        description: '중앙이 강화된 패턴',
        layout: [
          [1, 1, 2, 1, 1],
          [1, 2, 3, 2, 1],
          [2, 3, 4, 3, 2],
          [1, 2, 3, 2, 1],
          [1, 1, 2, 1, 1],
        ],
        hpMultiplier: 1.3,
      ),
    );

    // 패턴 10: 원형(마름모)
    _patterns.add(
      BrickPattern(
        name: 'Diamond',
        description: '마름모 형태 패턴',
        layout: [
          [0, 0, 2, 0, 0],
          [0, 2, 1, 2, 0],
          [2, 1, 3, 1, 2],
          [0, 2, 1, 2, 0],
          [0, 0, 2, 0, 0],
        ],
        hpMultiplier: 1.1,
      ),
    );
  }

  /// 새 웨이브 생성
  Future<void> generateNewWave() async {
    // 이전 웨이브의 벽돌 제거
    clearBricks();

    // 웨이브 카운터 증가
    currentWave++;

    // 무작위 패턴 또는 웨이브에 맞는 패턴 선택
    final pattern = _selectPattern();

    // 벽돌 생성 시작 위치 계산 (게임 화면 상단에 적절히 배치)
    // 카메라의 visibleWorldRect를 사용하여 월드 좌표계 위치 계산
    final visibleRect = gameRef.camera.visibleWorldRect;
    final startX =
        (visibleRect.width - (pattern.layout[0].length * brickWidth)) / 2 +
        visibleRect.left +
        (brickWidth / 2);
    final startY = visibleRect.top + 2.0; // 상단에서 약간 여유 공간

    // 벽돌 생성
    final bricks = pattern.generateBricks(
      waveIndex: currentWave,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
      startPosition: Vector2(startX, startY),
      applyRandomization: currentWave > 1, // 첫 웨이브는 변형 없이 기본 형태로
    );

    // 월드에 직접 벽돌 추가
    for (final brick in bricks) {
      // 게임이 아닌 월드에 직접 추가
      await gameRef.world.add(brick);
      _bricks.add(brick);
    }

    // 웨이브 시작
    gameRef.startWave();
  }

  /// 벽돌 패턴 선택 로직
  BrickPattern _selectPattern() {
    // 웨이브 번호에 따른 패턴 선택 로직
    if (currentWave == 1) {
      // 첫 웨이브는 항상 기본 라인 패턴
      return _patterns[0];
    }

    // 연속해서 같은 패턴이 나오지 않도록 함
    int patternIndex;
    do {
      // 웨이브가 높을수록 고급 패턴 등장 확률 증가
      if (currentWave > 5) {
        // 고급 패턴 선호 (인덱스 5-9)
        patternIndex = 5 + _random.nextInt(_patterns.length - 5);
      } else {
        // 모든 패턴 중에서 선택
        patternIndex = _random.nextInt(_patterns.length);
      }
    } while (patternIndex == _lastPatternIndex && _patterns.length > 1);

    _lastPatternIndex = patternIndex;
    return _patterns[patternIndex];
  }

  /// 모든 벽돌이 제거되었는지 확인
  bool areAllBricksCleared() {
    return _bricks.isEmpty;
  }

  /// 벽돌 제거
  void clearBricks() {
    for (final brick in _bricks) {
      brick.destroyImmediately();
    }
    _bricks.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 제거된 벽돌 목록에서 제거
    _bricks.removeWhere((brick) => !brick.isMounted);

    // 필요한 경우 추가 로직 구현
    // (예: 웨이브 전환 시 벽돌 애니메이션, 남은 벽돌 수 추적 등)
  }
}
