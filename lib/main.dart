import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 진입점
void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 방향 설정 (세로 모드만 허용)
  await Flame.device.setPortrait();

  // 상태 표시줄 숨기기 (전체 화면 모드)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 앱 실행
  runApp(const MyApp());
}

/// 앱 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '벽돌 체인 블래스터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

/// 게임 화면 위젯
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<BrickChainGame>(
        game: BrickChainGame(),
        loadingBuilder:
            (context) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '로딩 중...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        overlayBuilderMap: {
          'debug_info': (context, game) => DebugOverlay(game: game),
        },
        initialActiveOverlays: const [], // 디버그 모드에서는 'debug_info' 추가 가능
      ),
    );
  }
}

/// 디버그 오버레이 위젯
class DebugOverlay extends StatelessWidget {
  final BrickChainGame game;

  const DebugOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '웨이브: ${game.brickManager.currentWave}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              '벽돌: ${game.brickManager.brickCount}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              '볼: ${game.ballManager.balls.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
