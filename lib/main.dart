import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/brick_chain_game.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: GameScreen()),
  );
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget.controlled(gameFactory: BrickChainGame.new),
    );
  }
}
