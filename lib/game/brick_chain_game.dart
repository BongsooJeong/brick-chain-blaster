import 'dart:ui';
import 'dart:math' as math;
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

  // 중력 없이 시작, 이전 버전에서는 카메라 옵션이 생성자에 포함됨
  BrickChainGame() : super(gravity: Vector2(0, 0));

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 카메라 줌 설정 (이전 버전 호환성 방식)
    camera.zoom = 50.0;

    // 세계 경계 추가
    await addWorldBoundaries();

    // 테스트용 벽돌 추가
    await addTestBricks();

    // 테스트용 공 추가
    addBall();

    print('BrickChainGame 초기화 완료!');
  }

  /// 월드 경계 추가 메서드
  Future<void> addWorldBoundaries() async {
    final walls = [
      // 왼쪽 벽
      Wall(
        position: Vector2(0, worldHeight / 2),
        size: Vector2(0.2, worldHeight),
      ),

      // 오른쪽 벽
      Wall(
        position: Vector2(worldWidth, worldHeight / 2),
        size: Vector2(0.2, worldHeight),
      ),

      // 상단 벽
      Wall(
        position: Vector2(worldWidth / 2, 0),
        size: Vector2(worldWidth, 0.2),
      ),

      // 하단 벽 (없음 - 공이 떨어지도록)
    ];

    addAll(walls);
  }

  /// 테스트용 벽돌 추가 메서드
  Future<void> addTestBricks() async {
    final brickColors = [
      const Color(0xFFFF0000), // 빨강
      const Color(0xFFFF7F00), // 주황
      const Color(0xFFFFFF00), // 노랑
      const Color(0xFF00FF00), // 초록
      const Color(0xFF0000FF), // 파랑
      const Color(0xFF4B0082), // 남색
      const Color(0xFF9400D3), // 보라
    ];

    final random = math.Random();

    // 벽돌 크기
    const brickWidth = 1.5;
    const brickHeight = 0.6;

    // 벽돌 간격
    const horizontalGap = 0.1;
    const verticalGap = 0.1;

    // 벽돌 행과 열 계산
    final rows = 4;
    final cols = 5;

    // 벽돌 시작 위치 계산 (중앙 정렬)
    final startX =
        (worldWidth - (cols * (brickWidth + horizontalGap) - horizontalGap)) /
        2;
    final startY = 2.0; // 상단에서 2 단위 아래부터 시작

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final position = Vector2(
          startX + col * (brickWidth + horizontalGap) + brickWidth / 2,
          startY + row * (brickHeight + verticalGap) + brickHeight / 2,
        );

        final hitPoints = row + 1; // 위쪽 벽돌일수록 내구도 높음
        final colorIndex = row % brickColors.length;

        add(
          Brick(
            position: position,
            size: Vector2(brickWidth, brickHeight),
            hitPoints: hitPoints,
            color: brickColors[colorIndex],
          ),
        );
      }
    }
  }

  /// 테스트용 공 추가 메서드
  void addBall() {
    final ballPosition = Vector2(worldWidth / 2, worldHeight - 2.0);
    final ballVelocity = Vector2(3.0, -15.0); // 위쪽 방향으로 발사

    add(
      Ball(
        position: ballPosition,
        initialVelocity: ballVelocity,
        radius: 0.3,
        color: Colors.white,
      ),
    );
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
