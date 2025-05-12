import 'package:flutter/material.dart';
import 'config/env_config.dart';
import 'config/firebase_config.dart';
import 'views/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  EnvConfig.initialize(Environment.dev);
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  runApp(const BrickChainBlasterApp());
}

class BrickChainBlasterApp extends StatelessWidget {
  const BrickChainBlasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Chain Blaster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}