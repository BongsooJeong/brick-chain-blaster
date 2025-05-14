import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:forge2d/forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/camera.dart';
import 'package:brick_chain_blaster/components/ball.dart';
import 'package:brick_chain_blaster/components/brick.dart';
import 'package:brick_chain_blaster/components/wall.dart';
import 'package:brick_chain_blaster/managers/ball_manager.dart';
import 'package:brick_chain_blaster/managers/input_handler.dart';
import 'package:flutter/material.dart' show Colors;

/// 벽돌 체인 블래스터 게임 클래스
class BrickChainGame extends Forge2DGame {
  static const worldWidth = 9.0;
  static const worldHeight = 16.0;

  // ✔ 고정 해상도 뷰포트 + 카메라 생성
  BrickChainGame()
    : super(
        gravity: Vector2(0, 10),
        camera: CameraComponent.withFixedResolution(
          width: worldWidth,
          height: worldHeight,
        ),
      );

  // 공 관리자
  late final BallManager ballManager;

  // 입력 처리 관리자
  late final InputHandler inputHandler;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 개발 중에만 디버그 모드 사용 (배포 시 false로 변경)
    debugMode = false;

    // 세계 경계 추가
    await addWorldBoundaries();

    // 볼 매니저 초기화 및 추가
    ballManager = BallManager();
    await add(ballManager);

    // 입력 핸들러 초기화 및 추가
    inputHandler = InputHandler(ballManager: ballManager);
    await add(inputHandler);

    // 테스트용 벽돌 추가
    await addTestBricks();

    print('게임 초기화 완료: 월드 크기=${worldWidth}x$worldHeight');
  }

  // 세계 경계 추가
  Future<void> addWorldBoundaries() async {
    // 상하좌우 벽 추가
    await _addWall(
      Vector2(worldWidth / 2, 0),
      Vector2(worldWidth, 0.2),
    ); // 상단 벽
    await _addWall(
      Vector2(worldWidth / 2, worldHeight),
      Vector2(worldWidth, 0.2),
    ); // 하단 벽
    await _addWall(
      Vector2(0, worldHeight / 2),
      Vector2(0.2, worldHeight),
    ); // 좌측 벽
    await _addWall(
      Vector2(worldWidth, worldHeight / 2),
      Vector2(0.2, worldHeight),
    ); // 우측 벽

    print('경계 추가 완료');
  }

  // 벽 추가 헬퍼 메서드
  Future<Wall> _addWall(Vector2 position, Vector2 size) async {
    final wall = Wall(position: position, size: size);
    add(wall);
    return wall;
  }

  // 테스트용 벽돌 추가
  Future<void> addTestBricks() async {
    final brickSize = Vector2(1.0, 0.5);

    // 3x3 벽돌 그리드 추가
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final position = Vector2(
          2.0 + i * (brickSize.x + 0.5),
          3.0 + j * (brickSize.y + 0.5),
        );

        final brick = Brick(
          position: position,
          size: brickSize,
          hp: 1 + math.Random().nextInt(3), // 1-3 랜덤 HP
        );

        add(brick);
      }
    }

    print('테스트 벽돌 추가 완료');
  }
}

/// 테스트용 상자 클래스
class Box extends BodyComponent {
  @override
  final Vector2 position;
  final Vector2 size;

  Box(this.position, this.size);

  @override
  Body createBody() {
    final bodyDef =
        BodyDef()
          ..position = position
          ..type = BodyType.dynamic;

    final body = world.createBody(bodyDef);

    final shape =
        PolygonShape()..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0.0);

    final fixtureDef =
        FixtureDef(shape)
          ..restitution = 0.8
          ..friction = 0.2
          ..density = 1.0;

    body.createFixture(fixtureDef);

    return body;
  }
}
