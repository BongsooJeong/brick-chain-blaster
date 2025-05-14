import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// 벽돌 체인 블래스터 게임 클래스
class BrickChainGame extends FlameGame {
  // 배경색 설정
  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print('BrickChainGame 초기화 완료!');
  }
}