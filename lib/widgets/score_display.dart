import 'package:flutter/material.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 게임 점수를 표시하는 오버레이 위젯
class ScoreDisplay extends StatelessWidget {
  final BrickChainGame game;

  const ScoreDisplay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 40, left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Text(
                '점수: ${game.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.cyan, width: 2),
              ),
              child: Text(
                '웨이브: ${game.waveManager.currentWave ?? 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
