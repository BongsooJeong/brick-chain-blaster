import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '벽돌 체인 블래스터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SizedBox.expand(
          child: GameWidget<BrickChainGame>.controlled(
            gameFactory: () => BrickChainGame(),
            // Flame 1.28.1에서 웹에서 제대로 렌더링되도록 설정
            backgroundBuilder: (context) => Container(color: Colors.black),
            // 로딩 표시기
            loadingBuilder:
                (context) => const Center(child: CircularProgressIndicator()),
            // 오류 표시기
            errorBuilder:
                (context, error) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            // 필요한 경우 오버레이 Widget 추가
            overlayBuilderMap: {
              'score': (context, game) => const ScoreDisplay(),
            },
          ),
        ),
      ),
    );
  }
}

/// 점수 표시 위젯
class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 50,
      right: 50,
      child: Text('점수: 0', style: TextStyle(color: Colors.white, fontSize: 24)),
    );
  }
}
