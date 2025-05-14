import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:brick_chain_blaster/components/ball.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 공 상태 열거형
enum BallStatus {
  /// 대기 상태 (발사 준비 전)
  waiting,

  /// 준비 상태 (발사 대기)
  ready,

  /// 장전 상태 (발사 핀에 장착)
  loaded,

  /// 발사됨
  fired,

  /// 멈춤 (최종 위치에 도달)
  stopped,
}

/// 공 상태 관리 클래스
class _BallState {
  /// 현재 공 상태
  BallStatus status;

  /// 공 인스턴스 (발사 전에는 null)
  Ball? ball;

  /// 체인 내 인덱스
  final int index;

  /// 생성자
  _BallState({
    this.status = BallStatus.waiting,
    this.ball,
    required this.index,
  });
}

/// 공 체인 발사 메커니즘 관리 클래스
class BallManager extends Component with HasGameRef<BrickChainGame> {
  /// 현재 게임에 있는 공들의 목록
  final List<Ball> balls = [];

  /// 공 상태 추적 목록
  final List<_BallState> _ballStates = [];

  /// 발사할 공의 총 개수
  int ballCount = 5;

  /// 발사 중인지 상태
  bool isFiring = false;

  /// 발사 준비 중인지 상태 (트리거가 당겨졌지만 아직 발사 전)
  bool isPrimed = false;

  /// 발사 시작 위치 (월드 좌표 사용)
  Vector2 firingPosition = Vector2(4.5, 14.0);

  /// 조준 방향 (기본값: 위쪽)
  Vector2 aimDirection = Vector2(0, -1);

  /// 발사 간격 (밀리초)
  int firingDelay = 150;

  /// 공의 반지름
  double ballRadius = 0.3;

  /// 공의 색상
  Color ballColor = Colors.white;

  /// 공 발사 속도
  double ballSpeed = 10.0;

  /// 발사 핀 에너지 (0.0 ~ 1.0)
  double firingPinEnergy = 0.0;

  /// 최대 발사 핀 에너지 충전 속도
  double maxChargingRate = 3.0; // 초당 충전량

  /// 최소 발사 에너지 (이 값 이상에서만 발사 가능)
  double minFiringEnergy = 0.3;

  /// 충전 중인지 상태
  bool isCharging = false;

  /// 발사 진동 애니메이션 타이머
  double _firingAnimationTimer = 0.0;

  /// 진동 강도 (발사 애니메이션용)
  double _vibrationIntensity = 0.0;

  /// 마지막에 반환된 공 위치 (모든 공이 멈췄을 때)
  Vector2? _lastReturnPosition;

  /// 발사 시 약간의 무작위성을 적용하기 위한 난수 생성기
  final _random = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 초기 공 상태 설정
    _initializeBallStates();
  }

  /// 공 상태 초기화
  void _initializeBallStates() {
    _ballStates.clear();

    // 공 상태 생성
    for (int i = 0; i < ballCount; i++) {
      _ballStates.add(_BallState(status: BallStatus.waiting, index: i));
    }

    // 첫 번째 공은 준비 상태로 설정
    if (_ballStates.isNotEmpty) {
      _ballStates[0].status = BallStatus.ready;
    }
  }

  /// 발사 준비 시작 (충전 시작)
  void startCharging() {
    if (isFiring || isCharging) return;

    isCharging = true;
    firingPinEnergy = 0.0;
    print('발사 핀 충전 시작');
  }

  /// 발사 취소
  void cancelCharging() {
    if (!isCharging) return;

    isCharging = false;
    isPrimed = false;
    firingPinEnergy = 0.0;
    _vibrationIntensity = 0.0;
    print('발사 준비 취소');
  }

  /// 충전 완료 및 발사 준비
  void primeForFiring() {
    if (!isCharging || isFiring) return;

    if (firingPinEnergy < minFiringEnergy) {
      // 최소 에너지에 도달하지 못했으면 취소
      cancelCharging();
      return;
    }

    isCharging = false;
    isPrimed = true;
    _vibrationIntensity = firingPinEnergy * 0.1; // 에너지에 비례한 진동 강도
    print('발사 준비 완료, 에너지: ${firingPinEnergy.toStringAsFixed(2)}');
  }

  /// 새로운 공 생성
  Future<Ball> _createBall(Vector2 position) async {
    final ball = Ball(
      initialPosition: position,
      radius: ballRadius,
      color: ballColor,
      velocity: Vector2.zero(), // 공 생성자가 요구하는 velocity 파라미터
    );

    // 공을 월드에 직접 추가
    await gameRef.world.add(ball);
    balls.add(ball);

    return ball;
  }

  /// 볼 발사
  Future<void> fireBall(Vector2 direction) async {
    if (isFiring) return;

    // 첫 발사 시 준비
    isPrimed = true;
    isFiring = true;

    // 볼의 총 개수만큼 발사 (지연 간격 적용)
    for (int i = 0; i < ballCount; i++) {
      // 공 생성 및 발사
      final ball = await _createBall(firingPosition.clone());

      // 발사 방향에 속도 적용
      final normalizedDir = direction.normalized();
      final velocity = normalizedDir.scaled(ballSpeed);

      // 속도 설정 (Ball 클래스의 setVelocity 메서드 사용)
      ball.setVelocity(velocity);

      // 상태 업데이트
      _ballStates[i].status = BallStatus.fired;
      _ballStates[i].ball = ball;

      // 마지막 공이 아니면 지연 시간 적용
      if (i < ballCount - 1) {
        await Future.delayed(Duration(milliseconds: firingDelay));
      }
    }

    isFiring = false;
  }

  /// 모든 공을 원래 위치로 되돌림
  Future<void> resetBalls() async {
    // 모든 공 제거
    for (final ball in balls) {
      ball.removeFromParent();
    }
    balls.clear();

    // 상태 초기화
    _initializeBallStates();
    isFiring = false;
    isPrimed = false;
    isCharging = false;
    firingPinEnergy = 0.0;
    _vibrationIntensity = 0.0;
  }

  /// 모든 공이 멈췄는지 확인
  bool areAllBallsStopped() {
    if (balls.isEmpty) return true;

    try {
      // 모든 공 속도 확인
      for (final ball in balls) {
        try {
          // body가 null이 아니고 초기화되었으면 속도 확인
          if (ball.body.linearVelocity.length2 > 0.1) {
            return false;
          }
        } catch (e) {
          print('공 속도 확인 중 오류: $e');
          // 오류 발생 시 이 공은 무시
          continue;
        }
      }

      // 모든 공이 멈춤 (마지막 공의 위치 저장)
      if (balls.isNotEmpty) {
        _lastReturnPosition = balls.last.body.position.clone();

        // 상태 업데이트
        for (final state in _ballStates) {
          if (state.status == BallStatus.fired) {
            state.status = BallStatus.stopped;
          }
        }
      }

      return true;
    } catch (e) {
      print('areAllBallsStopped 메서드 오류: $e');
      return true; // 오류 발생 시 멈춘 것으로 간주
    }
  }

  /// 체인의 모든 공 위치를 계산하여 반환 (시각화용)
  List<Vector2> getChainedBallPositions() {
    final positions = <Vector2>[];

    // 발사된 공이 없으면 빈 목록 반환
    if (balls.isEmpty) return positions;

    // 첫 번째 공의 위치를 기준으로 선 그리기
    // (발사되지 않은 경우 발사 위치 사용)
    if (balls.isNotEmpty) {
      // Ball 클래스의 position 속성 사용
      final firstBallPos = balls[0].position.clone();
      // 첫 번째 공 위치 추가
      positions.add(firstBallPos);

      // 선 길이 계산을 위한 변수
      final lineLength = 6.0;
      final segmentCount = 10;
      final segmentLength = lineLength / segmentCount;

      // 발사 방향으로 선 세그먼트 추가
      final direction =
          (isPrimed && !isFiring)
              ? aimDirection.normalized()
              // Ball 클래스의 velocity 속성 사용
              : balls[0].velocity.normalized();

      for (int i = 1; i <= segmentCount; i++) {
        final offset = direction.scaled(i * segmentLength);
        final segmentPos = firstBallPos + offset;
        positions.add(segmentPos);
      }
    }

    return positions;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 충전 중이면 에너지 증가
    if (isCharging) {
      firingPinEnergy = math.min(firingPinEnergy + maxChargingRate * dt, 1.0);

      // 최대 충전 도달 시 자동으로 프라이밍
      if (firingPinEnergy >= 1.0) {
        primeForFiring();
      }
    }

    // 발사 준비 상태에서 진동 애니메이션 처리
    if (isPrimed) {
      _firingAnimationTimer += dt * 15.0; // 진동 속도
    } else {
      _firingAnimationTimer = 0.0;
    }

    // 발사 중이고 모든 공이 멈췄으면 발사 완료
    if (isFiring && areAllBallsStopped()) {
      isFiring = false;
      _onFiringComplete();
    }

    // 화면 밖으로 나간 공들 제거 (필요시 구현)
  }

  /// 발사 위치 진동 오프셋 계산 (발사 준비 애니메이션용)
  Vector2 getVibrationOffset() {
    // 발사 중에만 진동 효과
    if (!isFiring || balls.isEmpty) return Vector2.zero();

    // 랜덤 진동
    final maxOffset = 0.05;
    final dx = (math.Random().nextDouble() * 2 - 1) * maxOffset;
    final dy = (math.Random().nextDouble() * 2 - 1) * maxOffset;

    return Vector2(dx, dy);
  }

  /// 발사 완료 후 처리
  void _onFiringComplete() {
    // 새로운 발사 위치 (마지막 공의 위치 또는 원래 위치)
    firingPosition = _lastReturnPosition ?? firingPosition;

    // 게임 로직에 따라 다음 라운드 준비 (추가 구현 필요)
    print('모든 공 발사 완료. 새 발사 위치: $firingPosition');

    // 상태 초기화
    _initializeBallStates();
  }

  /// 모든 볼 제거
  void clearBalls() {
    for (final ball in balls) {
      ball.removeFromParent();
    }
    balls.clear();
    _ballStates.clear();
    _initializeBallStates();
  }
}
