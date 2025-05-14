import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/widgets.dart';

import '../components/ball.dart';
import '../components/wall.dart';
import '../components/brick.dart';
import '../components/brick_manager.dart';

/// Forge2D 기반 벽돌 깨기 게임
class Forge2DExample extends Forge2DGame
    with TapDetector, HasCollisionDetection {
  /// 벽돌 관리자
  late final BrickManager brickManager;

  /// 현재 웨이브
  int _currentWave = 1;

  /// 게임 상태
  bool _isGameOver = false;
  bool _isLevelComplete = false;
  bool _isLevelStarted = false;

  /// 생성자 - 중력은 위에서 아래로 약하게 설정
  Forge2DExample() : super(gravity: Vector2(0, 3.0));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // FPS 표시
    camera.viewport.add(FpsTextComponent());

    // 벽돌 관리자 생성
    brickManager = BrickManager(this, camera.visibleWorldRect.size.toVector2());
    add(brickManager);

    // 공 추가
    startLevel();
  }

  /// 레벨 시작
  void startLevel() {
    // 게임 상태 초기화
    _isGameOver = false;
    _isLevelComplete = false;
    _isLevelStarted = true;

    // 경계선 추가
    world.addAll(createBoundaries());

    // 벽돌 생성
    brickManager.currentWave = _currentWave;
    brickManager.generateStage();

    // 공 생성 (초기에는 화면 하단 중앙에 배치)
    final visibleRect = camera.visibleWorldRect;
    final ballPosition = Vector2(
      visibleRect.center.dx,
      visibleRect.bottom - 2.0,
    );

    world.add(Ball(initialPosition: ballPosition, radius: 0.4));
  }

  /// 다음 레벨로 진행
  void advanceToNextLevel() {
    // 기존 요소 제거
    _clearLevel();

    // 웨이브 증가
    _currentWave++;

    // 새 레벨 시작
    startLevel();
  }

  /// 게임 재시작
  void restartGame() {
    // 기존 요소 제거
    _clearLevel();

    // 웨이브 초기화
    _currentWave = 1;

    // 새 게임 시작
    startLevel();
  }

  /// 레벨 클리어 (모든 요소 제거)
  void _clearLevel() {
    // 공 제거
    final balls = world.children.whereType<Ball>().toList();
    for (final ball in balls) {
      ball.removeFromParent();
    }

    // 벽 제거
    final walls = world.children.whereType<Wall>().toList();
    for (final wall in walls) {
      wall.removeFromParent();
    }

    // 벽돌 제거
    brickManager.clearBricks();

    _isLevelStarted = false;
  }

  /// 경계선 생성
  List<Component> createBoundaries() {
    final visibleRect = camera.visibleWorldRect;
    final topLeft = visibleRect.topLeft.toVector2();
    final topRight = visibleRect.topRight.toVector2();
    final bottomRight = visibleRect.bottomRight.toVector2();
    final bottomLeft = visibleRect.bottomLeft.toVector2();

    // 벽 생성 (상단, 좌우 경계선만 만들고 하단은 열린 공간)
    return [
      Wall(start: topLeft, end: topRight), // 상단 벽
      Wall(start: topLeft, end: bottomLeft), // 좌측 벽
      Wall(start: topRight, end: bottomRight), // 우측 벽
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 게임이 진행 중일 때만 업데이트
    if (_isLevelStarted && !_isGameOver && !_isLevelComplete) {
      // 모든 벽돌 클리어 확인
      if (brickManager.areAllBricksCleared()) {
        _isLevelComplete = true;
        _handleLevelComplete();
      }

      // 공이 모두 사라졌는지 확인
      final balls = world.children.whereType<Ball>().toList();
      if (balls.isEmpty) {
        _isGameOver = true;
        _handleGameOver();
      }
    }
  }

  /// 레벨 클리어 처리
  void _handleLevelComplete() {
    print('레벨 클리어! 다음 웨이브: ${_currentWave + 1}');

    // 잠시 후 다음 레벨로 진행
    Future.delayed(const Duration(seconds: 2), () {
      advanceToNextLevel();
    });
  }

  /// 게임 오버 처리
  void _handleGameOver() {
    print('게임 오버!');

    // 잠시 후 게임 재시작
    Future.delayed(const Duration(seconds: 3), () {
      restartGame();
    });
  }

  @override
  void onTap() {
    super.onTap();

    // 레벨이 시작되지 않았으면 시작
    if (!_isLevelStarted) {
      startLevel();
      return;
    }

    // 게임 오버나 레벨 클리어 상태면 다음 단계로
    if (_isGameOver) {
      restartGame();
      return;
    }

    if (_isLevelComplete) {
      advanceToNextLevel();
      return;
    }

    // 공 추가
    final visibleRect = camera.visibleWorldRect;
    final ballPosition = Vector2(
      visibleRect.center.dx,
      visibleRect.bottom - 2.0,
    );

    world.add(Ball(initialPosition: ballPosition, radius: 0.4));
  }
}
