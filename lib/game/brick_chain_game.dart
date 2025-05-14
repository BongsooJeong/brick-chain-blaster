import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:forge2d/forge2d.dart' hide Vector2;
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:brick_chain_blaster/components/ball.dart';
import 'package:brick_chain_blaster/components/brick.dart';
import 'package:brick_chain_blaster/components/wall.dart';
import 'package:flutter/material.dart' show Colors;

/// 벽돌 체인 블래스터 게임 클래스
class BrickChainGame extends Forge2DGame {
  // 게임 세계의 크기
  static const double worldWidth = 9.0;
  static const double worldHeight = 16.0;

  // 중력 없이 시작
  BrickChainGame() : super(gravity: Vector2(0, 0));

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 카메라 설정 (Flame 1.28.0 버전에 맞게 조정)
    camera.viewfinder.zoom = 50.0;

    // 세계 경계 추가
    await addWorldBoundaries();

    // 테스트용 벽돌 추가
    await addTestBricks();

    // 테스트용 공 추가
    addBall();
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
  }

  // 테스트용 공 추가
  void addBall() {
    // 화면 중앙 하단에 공 추가
    final ball = Ball(
      position: Vector2(worldWidth / 2, worldHeight - 2),
      radius: 0.3,
      velocity: Vector2(2.0, -10.0),
    );

    add(ball);
  }
}

/// 테스트용 상자 클래스
class Box extends BodyComponent {
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
