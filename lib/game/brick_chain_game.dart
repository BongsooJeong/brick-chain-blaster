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
import 'package:brick_chain_blaster/managers/brick_manager.dart';
import 'package:brick_chain_blaster/managers/wave_manager.dart';
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
  BrickChainGame() : super(gravity: Vector2(0, 10));

  // 게임 매니저
  late BallManager ballManager;
  late InputHandler inputHandler;
  late BrickManager brickManager;
  late WaveManager waveManager;

  // 게임 상태
  bool gameStarted = false;

  // 점수
  int _score = 0;

  // 점수 getter
  int get score => _score;

  // 점수 증가 메서드
  void addScore(int points) {
    _score += points;
    // 향후 점수 변경 이벤트 발생 가능
  }

  /// 웨이브 시작
  void startWave() {
    // 웨이브가 시작될 때 게임 상태 업데이트
    gameStarted = true;

    // 필요한 경우 여기에 추가 로직 구현
    // 예: 사운드 재생, 애니메이션 트리거 등
    debugPrint('💫 새 웨이브 시작!');
  }

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

    // 디버그 모드 비활성화
    debugMode = false;

    // 세계 경계 추가
    await add(world);
    world.addAll(createBoundaries());

    // 볼 매니저 초기화 및 추가
    ballManager = BallManager();
    await add(ballManager);

    // 입력 핸들러 초기화 및 추가
    inputHandler = InputHandler(ballManager: ballManager);
    await add(inputHandler);

    // 벽돌 매니저 초기화 및 추가
    brickManager = BrickManager();
    await add(brickManager);

    // 웨이브 매니저 초기화 및 추가
    waveManager = WaveManager(brickManager: brickManager);
    await add(waveManager);

    // 볼과 벽돌의 충돌 처리 설정
    setupCollisions();

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

    // 로그 출력 (디버깅용)
    print(
      '🔄 zoom 설정: ${camera.viewfinder.zoom} (화면 ${canvasSize.x.toInt()}x${canvasSize.y.toInt()}, 월드 ${worldWidth}x$worldHeight)',
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 볼과 벽돌의 충돌 확인
    // 참고: Forge2D의 물리 엔진 충돌 감지를 대체하는 임시 로직
    // 추후 Forge2D의 충돌 콜백으로 교체하는 것이 더 효율적
    _checkBallBrickCollisions();
  }

  /// 볼과 벽돌의 충돌 처리 설정
  void setupCollisions() {
    // Forge2D 충돌 처리는 별도 구현 예정
    // 현재는 update에서 수동 확인
  }

  /// 볼과 벽돌 충돌 확인 (임시 구현)
  void _checkBallBrickCollisions() {
    if (brickManager.brickCount == 0) return;

    // 볼 목록 가져오기
    final balls = ballManager.balls;

    // 간단한 충돌 감지
    // 참고: 이것은 단순화된 로직이므로 실제 물리 기반 충돌 처리와는 다릅니다
    for (final ball in balls) {
      if (!ball.isMounted) continue;

      for (final brick in brickManager.activeBricks) {
        if (!brick.isMounted || brick.isDestroying) continue;

        // 볼과 벽돌 사이의 거리 계산
        final ballCenter = ball.body.position;
        final brickCenter = brick.body.position;
        final brickSize = brick.size;

        // 단순 사각형-원 충돌 테스트
        final halfWidth = brickSize.x / 2;
        final halfHeight = brickSize.y / 2;

        // 벽돌 중심에서 볼까지의 벡터
        final dx = (ballCenter.x - brickCenter.x).abs();
        final dy = (ballCenter.y - brickCenter.y).abs();

        // 벽돌 경계 밖으로 돌출된 거리
        final overlapX = dx - halfWidth - ball.radius;
        final overlapY = dy - halfHeight - ball.radius;

        // 충돌 발생
        if (overlapX < 0 && overlapY < 0) {
          // 벽돌에 데미지
          brick.hit();

          // 벽돌 파괴 시 점수 증가
          if (brick.currentHp <= 0) {
            // 벽돌 유형에 따라 다른 점수 부여
            switch (brick.type) {
              case BrickType.normal:
                addScore(10);
                break;
              case BrickType.special:
                addScore(30);
                break;
              case BrickType.reinforced:
                addScore(20 * brick.hp); // HP가 높을수록 더 많은 점수
                break;
              case BrickType.explosive:
                addScore(40); // 폭발성 벽돌은 높은 점수
                break;
              case BrickType.boss:
                addScore(50 * brick.hp); // 보스는 더 많은 점수
                break;
              case BrickType.powerup:
                addScore(25); // 파워업 벽돌
                break;
              case BrickType.moving:
                addScore(35); // 이동 벽돌
                break;
            }
          } else {
            // 부분 타격에도 작은 점수 부여
            addScore(1);
          }

          // 볼의 반사
          final ballVelocity = ball.body.linearVelocity;

          // 수평/수직 충돌 구분
          if (overlapX > overlapY) {
            // 수직 표면 충돌
            ball.body.linearVelocity = Vector2(
              -ballVelocity.x * 0.95,
              ballVelocity.y * 0.95,
            );
          } else {
            // 수평 표면 충돌
            ball.body.linearVelocity = Vector2(
              ballVelocity.x * 0.95,
              -ballVelocity.y * 0.95,
            );
          }

          // 충돌 시 속도 약간 증가 (게임성 향상)
          final speed = ball.body.linearVelocity.length;
          if (speed < 20) {
            // 최대 속도 제한
            ball.body.linearVelocity.scale(1.05);
          }

          // 충돌한 벽돌은 더 이상 처리하지 않음
          break;
        }
      }
    }
  }

  /// 게임 경계 벽 생성
  List<Wall> createBoundaries() {
    // 카메라의 월드 좌표 경계 얻기
    final visibleRect = camera.visibleWorldRect;
    final topLeft = visibleRect.topLeft.toVector2();
    final topRight = visibleRect.topRight.toVector2();
    final bottomRight = visibleRect.bottomRight.toVector2();
    final bottomLeft = visibleRect.bottomLeft.toVector2();

    // 경계선 위치에 벽 생성 (Wall.line 생성자 사용)
    return [
      // 상단 벽
      Wall.line(topLeft, topRight),
      // 우측 벽
      Wall.line(topRight, bottomRight),
      // 하단 벽 (공이 떨어지는 부분은 제외 가능)
      Wall.line(bottomLeft, bottomRight),
      // 좌측 벽
      Wall.line(topLeft, bottomLeft),
    ];
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
