import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/widgets.dart';

import '../components/ball.dart';
import '../components/wall.dart';
import '../components/brick.dart';

/// Forge2D 기반 게임 예제
class Forge2DExample extends Forge2DGame {
  Forge2DExample() : super(gravity: Vector2(0, 10.0));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // FPS 표시
    camera.viewport.add(FpsTextComponent());

    // 공 추가
    world.add(Ball());

    // 경계선 추가
    world.addAll(createBoundaries());

    // 벽돌 추가
    addBricks();
  }

  /// 경계선 생성
  List<Component> createBoundaries() {
    final visibleRect = camera.visibleWorldRect;
    final topLeft = visibleRect.topLeft.toVector2();
    final topRight = visibleRect.topRight.toVector2();
    final bottomRight = visibleRect.bottomRight.toVector2();
    final bottomLeft = visibleRect.bottomLeft.toVector2();

    return [
      Wall(start: topLeft, end: topRight),
      Wall(start: topRight, end: bottomRight),
      Wall(start: bottomLeft, end: bottomRight),
      Wall(start: topLeft, end: bottomLeft),
    ];
  }

  /// 벽돌 추가
  void addBricks() {
    final visibleRect = camera.visibleWorldRect;
    final width = visibleRect.width;
    final height = visibleRect.height;

    // 벽돌 사이즈
    final brickSize = Vector2(width / 10, height / 40);

    // 상단에 벽돌 배치
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 8; col++) {
        // 행에 따라 벽돌 타입 결정
        final type =
            row == 0
                ? BrickType.reinforced
                : row == 4
                ? BrickType.special
                : BrickType.normal;

        // 위치 계산 - 상단 중앙 정렬
        final x =
            visibleRect.left + (col + 0.5) * brickSize.x * 1.2 + width * 0.1;
        final y =
            visibleRect.top + (row + 1) * brickSize.y * 1.3 + height * 0.1;

        // 벽돌 추가
        world.add(Brick(position: Vector2(x, y), size: brickSize, type: type));
      }
    }

    // 보스 벽돌 추가 (중앙)
    world.add(
      Brick(
        position: Vector2(
          visibleRect.center.dx,
          visibleRect.center.dy - height * 0.2,
        ),
        size: brickSize * 2.5,
        type: BrickType.boss,
      ),
    );
  }
}
