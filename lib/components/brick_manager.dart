import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'brick.dart';

/// 벽돌 패턴 정의
class BrickPattern {
  final List<List<int>> layout;
  final double hpMultiplier;
  final String name;

  const BrickPattern({
    required this.layout,
    required this.name,
    this.hpMultiplier = 1.0,
  });

  /// 레이아웃을 뒤집기
  BrickPattern flipHorizontal() {
    final newLayout = <List<int>>[];
    for (var row in layout) {
      newLayout.add(List<int>.from(row.reversed));
    }
    return BrickPattern(
      layout: newLayout,
      name: '$name (H-flipped)',
      hpMultiplier: hpMultiplier,
    );
  }

  /// 레이아웃을 상하 뒤집기
  BrickPattern flipVertical() {
    final List<List<int>> newLayout = [];
    for (var row in layout.reversed) {
      newLayout.add(List<int>.from(row));
    }
    return BrickPattern(
      layout: newLayout,
      name: '$name (V-flipped)',
      hpMultiplier: hpMultiplier,
    );
  }
}

/// 벽돌 관리자
class BrickManager extends Component {
  final Vector2 gameSize;
  final Forge2DGame game;

  /// 벽돌 목록
  final List<Brick> bricks = [];

  /// 현재 웨이브
  int _currentWave = 1;

  /// 패턴 라이브러리
  final List<BrickPattern> _patterns = [];

  /// 랜덤 생성기
  final Random _random = Random();

  BrickManager(this.game, this.gameSize) {
    _initializePatterns();
  }

  /// 패턴 라이브러리 초기화
  void _initializePatterns() {
    // 패턴 1: 기본 라인
    _patterns.add(
      BrickPattern(
        name: '기본 라인',
        layout: [
          [1, 1, 1, 1, 1, 1, 1, 1],
          [0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0],
        ],
      ),
    );

    // 패턴 2: 격자 패턴
    _patterns.add(
      BrickPattern(
        name: '격자 패턴',
        layout: [
          [1, 0, 1, 0, 1, 0, 1, 0],
          [0, 1, 0, 1, 0, 1, 0, 1],
          [1, 0, 1, 0, 1, 0, 1, 0],
          [0, 1, 0, 1, 0, 1, 0, 1],
        ],
      ),
    );

    // 패턴 3: 피라미드
    _patterns.add(
      BrickPattern(
        name: '피라미드',
        layout: [
          [0, 0, 0, 1, 1, 0, 0, 0],
          [0, 0, 1, 1, 1, 1, 0, 0],
          [0, 1, 1, 1, 1, 1, 1, 0],
          [1, 1, 1, 1, 1, 1, 1, 1],
        ],
        hpMultiplier: 1.2,
      ),
    );

    // 패턴 4: 지그재그
    _patterns.add(
      BrickPattern(
        name: '지그재그',
        layout: [
          [1, 1, 0, 0, 0, 0, 1, 1],
          [0, 1, 1, 0, 0, 1, 1, 0],
          [0, 0, 1, 1, 1, 1, 0, 0],
          [0, 0, 0, 1, 1, 0, 0, 0],
        ],
      ),
    );

    // 패턴 5: 요새 패턴
    _patterns.add(
      BrickPattern(
        name: '요새',
        layout: [
          [1, 1, 1, 1, 1, 1, 1, 1],
          [1, 0, 0, 0, 0, 0, 0, 1],
          [1, 0, 0, 0, 0, 0, 0, 1],
          [1, 1, 1, 1, 1, 1, 1, 1],
        ],
        hpMultiplier: 1.5,
      ),
    );

    // 패턴 6: X자 패턴
    _patterns.add(
      BrickPattern(
        name: 'X자 패턴',
        layout: [
          [1, 0, 0, 0, 0, 0, 0, 1],
          [0, 1, 0, 0, 0, 0, 1, 0],
          [0, 0, 1, 0, 0, 1, 0, 0],
          [0, 0, 0, 1, 1, 0, 0, 0],
          [0, 0, 0, 1, 1, 0, 0, 0],
          [0, 0, 1, 0, 0, 1, 0, 0],
          [0, 1, 0, 0, 0, 0, 1, 0],
          [1, 0, 0, 0, 0, 0, 0, 1],
        ],
      ),
    );

    // 패턴 7: 아치 형태
    _patterns.add(
      BrickPattern(
        name: '아치',
        layout: [
          [1, 1, 1, 1, 1, 1, 1, 1],
          [1, 0, 0, 0, 0, 0, 0, 1],
          [1, 0, 0, 0, 0, 0, 0, 1],
          [0, 0, 0, 0, 0, 0, 0, 0],
        ],
      ),
    );

    // 패턴 8: 대각선 삼각형
    _patterns.add(
      BrickPattern(
        name: '대각선 삼각형',
        layout: [
          [1, 0, 0, 0, 0, 0, 0, 0],
          [1, 1, 0, 0, 0, 0, 0, 0],
          [1, 1, 1, 0, 0, 0, 0, 0],
          [1, 1, 1, 1, 0, 0, 0, 0],
          [1, 1, 1, 1, 1, 0, 0, 0],
          [1, 1, 1, 1, 1, 1, 0, 0],
          [1, 1, 1, 1, 1, 1, 1, 0],
          [1, 1, 1, 1, 1, 1, 1, 1],
        ],
      ),
    );

    // 패턴 9: 강화 중앙
    _patterns.add(
      BrickPattern(
        name: '강화 중앙',
        layout: [
          [1, 1, 1, 1, 1, 1, 1, 1],
          [1, 2, 2, 2, 2, 2, 2, 1],
          [1, 2, 3, 3, 3, 3, 2, 1],
          [1, 2, 3, 4, 4, 3, 2, 1],
          [1, 2, 3, 4, 4, 3, 2, 1],
          [1, 2, 3, 3, 3, 3, 2, 1],
          [1, 2, 2, 2, 2, 2, 2, 1],
          [1, 1, 1, 1, 1, 1, 1, 1],
        ],
        hpMultiplier: 0.7, // 숫자가 이미 크므로 곱셈값은 작게
      ),
    );

    // 패턴 10: 다이아몬드
    _patterns.add(
      BrickPattern(
        name: '다이아몬드',
        layout: [
          [0, 0, 0, 1, 1, 0, 0, 0],
          [0, 0, 1, 2, 2, 1, 0, 0],
          [0, 1, 2, 3, 3, 2, 1, 0],
          [1, 2, 3, 4, 4, 3, 2, 1],
          [1, 2, 3, 4, 4, 3, 2, 1],
          [0, 1, 2, 3, 3, 2, 1, 0],
          [0, 0, 1, 2, 2, 1, 0, 0],
          [0, 0, 0, 1, 1, 0, 0, 0],
        ],
        hpMultiplier: 0.6,
      ),
    );

    // 변형된 패턴 추가 (좌우/상하 뒤집기)
    final originalPatterns = List<BrickPattern>.from(_patterns);
    for (var pattern in originalPatterns) {
      // 50% 확률로 좌우 뒤집기 추가
      if (_random.nextBool()) {
        _patterns.add(pattern.flipHorizontal());
      }

      // 30% 확률로 상하 뒤집기 추가
      if (_random.nextDouble() < 0.3) {
        _patterns.add(pattern.flipVertical());
      }
    }
  }

  /// 현재 웨이브 설정
  set currentWave(int value) {
    _currentWave = value;
  }

  /// 현재 웨이브 반환
  int get currentWave => _currentWave;

  /// 스테이지 생성
  void generateStage() {
    clearBricks();

    // 패턴 선택
    final pattern = _selectPattern();

    // 벽돌 크기 계산 (화면 크기에 비례)
    final brickWidth = gameSize.x / 12; // 여유 공간 확보
    final brickHeight = brickWidth * 0.4; // 벽돌 높이는 너비의 40%

    // 패턴 중앙 정렬을 위한 오프셋 계산
    final patternWidth = pattern.layout[0].length * brickWidth;
    final startX = (gameSize.x - patternWidth) / 2 + brickWidth / 2;
    final startY = gameSize.y * 0.15; // 화면 상단에서 15% 위치

    // 기본 HP 계산
    final baseHP = _calculateBaseHP();

    // 특수 벽돌 확률 (웨이브가 높을수록 증가)
    final specialBrickChance = min(0.25, 0.05 + _currentWave * 0.02);

    // 패턴에 따라 벽돌 생성
    for (int row = 0; row < pattern.layout.length; row++) {
      for (int col = 0; col < pattern.layout[row].length; col++) {
        final value = pattern.layout[row][col];

        if (value > 0) {
          // 위치 계산
          final x = startX + col * brickWidth;
          final y = startY + row * brickHeight * 1.2; // 약간의 간격
          final position = Vector2(x, y);

          // HP 계산 (패턴 값 * 기본 HP * 멀티플라이어)
          final hp = max(1, (value * baseHP * pattern.hpMultiplier).round());

          // 벽돌 타입 결정
          BrickType brickType;

          // 값이 크면 더 강한 벽돌 타입 사용
          if (value >= 4) {
            brickType = BrickType.boss;
          } else if (value >= 3) {
            brickType = BrickType.reinforced;
          } else {
            // 기본 벽돌 또는 특수 벽돌 (확률에 따라)
            if (_random.nextDouble() < specialBrickChance) {
              // 특수 벽돌 종류 결정
              final specialType = _random.nextDouble();
              if (specialType < 0.4) {
                brickType = BrickType.explosive;
              } else if (specialType < 0.8) {
                brickType = BrickType.powerup;
              } else {
                brickType = BrickType.moving;
              }
            } else {
              brickType = BrickType.normal;
            }
          }

          // 벽돌 생성
          final brick = Brick(
            position: position,
            size: Vector2(brickWidth * 0.9, brickHeight * 0.9), // 약간의 간격
            hp: hp,
            type: brickType,
            onEffectActivated: _handleBrickEffect,
          );

          // 이동 벽돌 설정
          if (brickType == BrickType.moving) {
            brick.setBounds(gameSize);

            // 랜덤 방향 설정
            final speed = 2.0 + _random.nextDouble() * 2.0;
            final angle = _random.nextDouble() * 2 * pi;
            final velocity = Vector2(speed * cos(angle), speed * sin(angle));
            brick.setVelocity(velocity);
          }

          // 게임에 추가
          game.world.add(brick);
          bricks.add(brick);
        }
      }
    }
  }

  /// 특수 벽돌 효과 처리
  void _handleBrickEffect(Brick brick, BrickType effectType) {
    switch (effectType) {
      case BrickType.explosive:
        _createExplosion(brick.position, 3.0);
        break;

      case BrickType.powerup:
        _dropPowerup(brick.position);
        break;

      case BrickType.moving:
        // 이동 벽돌은 파괴될 때 추가 효과 없음
        break;

      case BrickType.boss:
        // 보스 벽돌은 파괴될 때 큰 폭발
        _createExplosion(brick.position, 5.0);
        break;

      default:
        // 다른 타입은 특별한 효과 없음
        break;
    }
  }

  /// 폭발 효과 생성 - 주변 벽돌에 데미지
  void _createExplosion(Vector2 position, double radius) {
    // 폭발 영향을 받는 벽돌 찾기
    for (final brick in List<Brick>.from(bricks)) {
      if (!brick.isDestroying) {
        final distance = brick.position.distanceTo(position);

        // 폭발 반경 내에 있는 벽돌에 데미지
        if (distance <= radius) {
          brick.hit();
        }
      }
    }

    // 폭발 시각 효과 추가 (향후 구현)
    // TODO: 폭발 파티클 효과 추가
  }

  /// 파워업 아이템 드롭
  void _dropPowerup(Vector2 position) {
    // TODO: 아이템 클래스 구현 후 아이템 생성 로직 추가
    print('파워업 아이템 드롭: $position');
  }

  /// 패턴 선택
  BrickPattern _selectPattern() {
    // 웨이브 번호에 따라 패턴 선택 확률 조정
    final patternIndex = _random.nextInt(_patterns.length);
    return _patterns[patternIndex];
  }

  /// 기본 HP 계산 (웨이브에 따라 증가)
  int _calculateBaseHP() {
    // 로그 함수로 완만한 증가 (웨이브 1: HP 1, 웨이브 2: HP 2, 웨이브 5: HP 3-4, 웨이브 10: HP 4-5)
    return max(1, (log(_currentWave + 1) / log(2)).round());
  }

  /// 모든 벽돌 제거
  void clearBricks() {
    for (final brick in bricks) {
      brick.destroyImmediately();
    }
    bricks.clear();
  }

  /// 벽돌 추가
  void addBrick(Brick brick) {
    bricks.add(brick);
    game.world.add(brick);
  }

  /// 모든 벽돌이 제거되었는지 확인
  bool areAllBricksCleared() {
    // 비활성화된 벽돌 제거
    bricks.removeWhere((brick) => !brick.isMounted);
    return bricks.isEmpty;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 제거된 벽돌 정리
    bricks.removeWhere((brick) => !brick.isMounted);
  }
}
