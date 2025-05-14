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
import 'package:flutter/foundation.dart' show debugPrint, debugPrintStack;

/// 뷰포트 경계를 시각적으로 표시하는 컴포넌트
class ViewportBorder extends Component with HasGameReference<BrickChainGame> {
  @override
  void render(Canvas c) {
    final Paint p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFFFF00FF); // 자홍색

    // 게임 화면 크기에 맞게 직사각형 그리기
    final rect = Rect.fromLTWH(0, 0, game.size.x, game.size.y);
    c.drawRect(rect, p);
  }
}

/// 벽돌 체인 블래스터 게임 클래스
class BrickChainGame extends Forge2DGame {
  // 월드 크기 - Forge2D에서는 일반적으로 작은 수치를 사용
  static const worldWidth = 9.0;
  static const worldHeight = 16.0;

  // 생성자
  BrickChainGame()
    : super(
        // Forge2D 월드의 중력 설정
        gravity: Vector2(0, 10),
        // 고정 해상도 카메라 - 월드 단위가 아닌 화면 단위로 설정
        camera: CameraComponent.withFixedResolution(
          width: 360, // 실제 픽셀 단위로 지정
          height: 640, // 실제 픽셀 단위로 지정
        ),
      );

  // 게임 매니저
  late BallManager ballManager;
  late InputHandler inputHandler;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 디버그 정보 출력
    debugPrint('🟢 게임 초기화 - 카메라 정보:');
    debugPrint('🟢 camera.viewfinder.position = ${camera.viewfinder.position}');
    debugPrint('🟢 camera.viewfinder.zoom = ${camera.viewfinder.zoom}');
    debugPrint('🟢 camera.viewport = ${camera.viewport.runtimeType}');
    debugPrint('🟢 visibleWorldRect = ${camera.visibleWorldRect}');

    // 카메라 앵커 설정 - 화면 중앙을 기준으로
    camera.viewfinder.anchor = Anchor.center;

    // 카메라 위치 설정 - 월드 중앙으로
    camera.viewfinder.position = Vector2(worldWidth / 2, worldHeight / 2);

    // 줌 설정 - zoom 값을 명시적으로 조정하지 않음
    // 대신 전체 화면 표시를 위해 viewport 비율에 따라 자동 계산되도록 함

    // 디버그 모드 비활성화
    debugMode = false;

    // 세계 경계 추가
    await addWorldBoundaries();

    // 볼 매니저 초기화 및 추가
    ballManager = BallManager();
    await add(ballManager);

    // 입력 핸들러 초기화 및 추가
    inputHandler = InputHandler(ballManager: ballManager);
    await add(inputHandler);

    // 디버그 정보 다시 출력
    debugPrint('🟢 초기화 완료 - 카메라 확인:');
    debugPrint('🟢 camera.viewfinder.zoom = ${camera.viewfinder.zoom}');
    debugPrint('🟢 visibleWorldRect = ${camera.visibleWorldRect}');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    debugPrint('[Resize] canvas=$canvasSize');

    // 동적 zoom 재계산 - 월드 크기에 맞게 zoom 조정
    final worldAspectRatio = worldWidth / worldHeight;
    final screenAspectRatio = canvasSize.x / canvasSize.y;

    // 화면 비율에 따라 zoom 값 조정
    if (screenAspectRatio > worldAspectRatio) {
      // 화면이 더 넓은 경우 - 높이에 맞춤
      camera.viewfinder.zoom = canvasSize.y / worldHeight;
    } else {
      // 화면이 더 좁은 경우 - 너비에 맞춤
      camera.viewfinder.zoom = canvasSize.x / worldWidth;
    }

    debugPrint(
      '🔄 zoom 설정: ${camera.viewfinder.zoom} (화면 ${canvasSize.x}x${canvasSize.y}, 월드 ${worldWidth}x$worldHeight)',
    );
  }

  // 화면 경계 추가
  Future<void> addWorldBoundaries() async {
    // 바닥
    final bottomWall = Wall(
      position: Vector2(worldWidth / 2, worldHeight),
      size: Vector2(worldWidth, 0.1),
    );

    // 왼쪽 벽
    final leftWall = Wall(
      position: Vector2(0, worldHeight / 2),
      size: Vector2(0.1, worldHeight),
    );

    // 오른쪽 벽
    final rightWall = Wall(
      position: Vector2(worldWidth, worldHeight / 2),
      size: Vector2(0.1, worldHeight),
    );

    // 위 벽
    final topWall = Wall(
      position: Vector2(worldWidth / 2, 0),
      size: Vector2(worldWidth, 0.1),
    );

    await addAll([bottomWall, leftWall, rightWall, topWall]);
  }

  /// 테스트를 위한 벽돌 추가 메서드
  Future<void> addTestBricks() async {
    final brickWidth = 1.5;
    final brickHeight = 0.6;
    final rows = 5;
    final cols = 5;
    final startX = (worldWidth - (cols * brickWidth)) / 2 + brickWidth / 2;
    final startY = 2.0;

    // 벽돌 행렬 생성
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        await add(
          Brick(
            position: Vector2(
              startX + col * brickWidth,
              startY + row * brickHeight,
            ),
            size: Vector2(brickWidth * 0.9, brickHeight * 0.9),
            hp: row + 1,
          ),
        );
      }
    }
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
