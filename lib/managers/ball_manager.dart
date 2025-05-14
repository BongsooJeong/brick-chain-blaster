import 'dart:async';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:brick_chain_blaster/components/ball.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';

/// 공 체인 발사 메커니즘 관리 클래스
class BallManager extends Component with HasGameRef<BrickChainGame> {
  /// 현재 게임에 있는 공들의 목록
  final List<Ball> balls = [];

  /// 발사할 공의 총 개수
  int ballCount = 1;

  /// 발사 중인지 상태
  bool isFiring = false;

  /// 발사 시작 위치
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

  /// 마지막에 반환된 공 위치 (모든 공이 멈췄을 때)
  Vector2? _lastReturnPosition;

  /// 메인 Thread가 블로킹되지 않도록 비동기 메서드로 구현
  Future<void> startFiring(Vector2 direction) async {
    if (isFiring) return;

    print('공 발사 시작: 방향 = $direction');
    isFiring = true;
    aimDirection = direction.normalized();

    try {
      // 모든 공을 발사
      for (int i = 0; i < ballCount; i++) {
        await _fireBall(aimDirection);

        // 발사 간격 대기
        if (i < ballCount - 1) {
          await Future.delayed(Duration(milliseconds: firingDelay));
        }
      }
    } catch (e) {
      print('공 발사 중 오류: $e');
    } finally {
      print('공 발사 완료');
    }
  }

  /// 단일 공 발사 메서드
  Future<void> _fireBall(Vector2 direction) async {
    if (!gameRef.children.contains(this)) {
      print('BallManager가 게임에 추가되지 않음');
      return;
    }

    try {
      // 가속 방향 계산 (정규화된 방향 * 속도)
      final velocity = direction.clone()..scale(ballSpeed);

      // 새 공 생성
      final ball = Ball(
        position: firingPosition.clone(),
        radius: ballRadius,
        color: ballColor,
        velocity: velocity,
      );

      // 게임에 공 추가
      await gameRef.add(ball);

      // 공 목록에 추가
      balls.add(ball);

      print('공 발사됨: 위치 = ${ball.position}, 속도 = $velocity');
    } catch (e) {
      print('_fireBall 메서드 오류: $e');
    }
  }

  /// 모든 공을 원래 위치로 되돌림
  Future<void> resetBalls() async {
    // 모든 공 제거
    for (final ball in balls) {
      ball.removeFromParent();
    }
    balls.clear();
    isFiring = false;
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
        _lastReturnPosition = balls.last.position.clone();
      }

      return true;
    } catch (e) {
      print('areAllBallsStopped 메서드 오류: $e');
      return true; // 오류 발생 시 멈춘 것으로 간주
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 발사 중이고 모든 공이 멈췄으면 발사 완료
    if (isFiring && areAllBallsStopped()) {
      isFiring = false;
      _onFiringComplete();
    }

    // 화면 밖으로 나간 공들 제거 (필요시 구현)
  }

  /// 발사 완료 후 처리
  void _onFiringComplete() {
    // 새로운 발사 위치 (마지막 공의 위치 또는 원래 위치)
    firingPosition = _lastReturnPosition ?? firingPosition;

    // 게임 로직에 따라 다음 라운드 준비 (추가 구현 필요)
    print('모든 공 발사 완료. 새 발사 위치: $firingPosition');
  }
}
