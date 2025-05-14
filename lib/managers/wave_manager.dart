import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, TextStyle, FontWeight;
import 'package:brick_chain_blaster/game/brick_chain_game.dart';
import 'package:brick_chain_blaster/managers/brick_manager.dart';

/// 웨이브 상태 열거형
enum WaveState {
  /// 웨이브 준비 중
  preparing,

  /// 웨이브 진행 중
  active,

  /// 웨이브 클리어됨
  cleared,

  /// 게임 종료됨
  gameOver,
}

/// 웨이브 매니저 클래스 - 웨이브 진행 및 관리
class WaveManager extends Component with HasGameRef<BrickChainGame> {
  /// 현재 웨이브 상태
  WaveState _state = WaveState.preparing;

  /// 웨이브 상태 getter
  WaveState get state => _state;

  /// 웨이브 텍스트 표시 여부
  final bool _waveTextVisible = true;

  /// 벽돌 매니저 참조
  late final BrickManager brickManager;

  /// 웨이브 시작 카운트다운 타이머
  Timer? _waveStartTimer;

  /// 웨이브 시작 카운트다운 남은 시간
  double _waveStartCountdown = 3.0;

  /// 웨이브 카운트다운 표시 컴포넌트
  final TextComponent _countdownText = TextComponent(
    text: '',
    textRenderer: TextPaint(
      style: const TextStyle(
        fontSize: 60,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    anchor: Anchor.center,
  );

  /// 웨이브 상태 표시 컴포넌트
  final TextComponent _waveText = TextComponent(
    text: '',
    textRenderer: TextPaint(
      style: const TextStyle(fontSize: 24, color: Colors.white),
    ),
    anchor: Anchor.center,
  );

  /// 현재 웨이브 번호 getter
  int get currentWave => brickManager.currentWave;

  /// 생성자
  WaveManager({required this.brickManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 텍스트 컴포넌트 추가 (월드 좌표계에 맞게 위치 지정)
    _countdownText.position = Vector2(
      BrickChainGame.worldWidth / 2,
      BrickChainGame.worldHeight / 2,
    );
    _waveText.position = Vector2(
      BrickChainGame.worldWidth / 2,
      BrickChainGame.worldHeight / 2 - 3,
    );

    await add(_countdownText);
    await add(_waveText);

    // 첫 웨이브 준비 시작
    prepareNextWave();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 타이머 업데이트
    if (_waveStartTimer != null) {
      _waveStartTimer!.update(dt);
      _updateCountdownDisplay();
    }

    // 웨이브 상태 업데이트
    if (_state == WaveState.active) {
      _checkWaveCompletion();
    }
  }

  /// 카운트다운 표시 업데이트
  void _updateCountdownDisplay() {
    if (_waveStartTimer == null) return;

    // 초 단위로 남은 시간 계산
    final secondsLeft = _waveStartCountdown.ceil();

    if (secondsLeft > 0) {
      _countdownText.text = '$secondsLeft';

      // 웨이브 시작 표시
      if (brickManager.currentWave == 0) {
        _waveText.text = '게임 시작!';
      } else {
        _waveText.text = '웨이브 ${brickManager.currentWave + 1} 시작!';
      }
    } else {
      // 카운트다운 종료 시 텍스트 비우기
      _countdownText.text = '';
      _waveText.text = '';
    }
  }

  /// 다음 웨이브 준비
  void prepareNextWave() {
    // 상태 변경
    _state = WaveState.preparing;

    // 카운트다운 설정
    _waveStartCountdown = brickManager.currentWave == 0 ? 3.0 : 2.0;

    // 카운트다운 표시 설정
    _updateCountdownDisplay();

    // 타이머 생성
    _waveStartTimer = Timer(_waveStartCountdown, onTick: startWave);
  }

  /// 웨이브 시작
  void startWave() {
    // 타이머 초기화
    _waveStartTimer = null;
    _countdownText.text = '';
    _waveText.text = '';

    // 벽돌 생성
    brickManager.generateNewWave();

    // 상태 변경
    _state = WaveState.active;
  }

  /// 웨이브 완료 확인
  void _checkWaveCompletion() {
    if (brickManager.areAllBricksCleared()) {
      _state = WaveState.cleared;
      _onWaveCleared();
    }
  }

  /// 웨이브 클리어 시 처리
  void _onWaveCleared() {
    print('웨이브 ${brickManager.currentWave} 클리어됨!');

    // 다음 웨이브 준비 (지연 시간 적용)
    Future.delayed(const Duration(seconds: 1), () {
      prepareNextWave();
    });
  }

  /// 게임 오버 처리
  void gameOver() {
    _state = WaveState.gameOver;
    _countdownText.text = 'GAME OVER';

    // 게임 오버 시 추가 처리 구현
  }

  @override
  void render(Canvas canvas) {
    if (!_waveTextVisible) return;

    // 카메라의 월드 좌표 경계 얻기
    final visibleRect = gameRef.camera.visibleWorldRect;
    final centerX = visibleRect.center.dx;
    final topY = visibleRect.top + 2.0; // 상단에서 약간 아래로

    final waveText =
        _state == WaveState.preparing ? '웨이브 $_waveStartCountdown' : '웨이브 시작!';

    // 웨이브 텍스트 그리기
    final textConfig = TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
      ),
    );

    // 화면 상단 중앙에 텍스트 그리기
    textConfig.render(
      canvas,
      waveText,
      Vector2(centerX, topY),
      anchor: Anchor.topCenter,
    );
  }
}
