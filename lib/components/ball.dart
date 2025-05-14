import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math' as math;

import 'brick.dart'; // Brick 클래스 임포트 추가

/// 게임 볼 컴포넌트 클래스
class Ball extends BodyComponent with TapCallbacks, ContactCallbacks {
  final Vector2? initialPosition;
  final double radius;
  final double restitution;
  final double density;
  final double friction;
  final Color color;
  final double minSpeed;
  final double maxSpeed;

  // 충돌 시간 추적
  final Set<Fixture> _contactFixtures = {};

  /// 생성자
  /// [initialPosition] 공의 초기 위치
  /// [radius] 공의 반지름
  /// [restitution] 반발 계수
  /// [density] 밀도
  /// [friction] 마찰 계수
  /// [color] 공의 색상
  /// [minSpeed] 최소 속도
  /// [maxSpeed] 최대 속도
  Ball({
    this.initialPosition,
    this.radius = 0.3,
    this.restitution = 0.8,
    this.density = 1.0,
    this.friction = 0.4,
    this.color = Colors.white,
    this.minSpeed = 10.0,
    this.maxSpeed = 20.0,
    super.priority = 1,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 그려질 모양 추가
    renderBody = true;
    paint = Paint()..color = Colors.white;
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: initialPosition ?? Vector2.zero(),
      type: BodyType.dynamic,
      userData: this, // 객체 참조 설정 (충돌 처리시 사용)
      angularDamping: 0.8,
      bullet: true, // 고속 충돌 처리 최적화
      fixedRotation: false, // 회전 허용
    );

    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(
      shape,
      restitution: restitution,
      density: density,
      friction: friction,
      filter:
          Filter()
            ..categoryBits =
                0x0002 // 볼 카테고리
            ..maskBits = 0xFFFF, // 모든 객체와 충돌
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 볼을 탭하면 무작위 방향으로 힘 적용
    body.applyLinearImpulse(Vector2.random() * 10);
  }

  /// 볼 리셋 (위치 및 속도)
  void reset(Vector2 position) {
    body.setTransform(position, 0);
    body.linearVelocity = Vector2.zero();
    body.angularVelocity = 0;
  }

  /// 발사 메서드 - 지정된 방향과 세기로 볼 발사
  void launch(Vector2 direction, double power) {
    // 방향 정규화 및 힘 적용
    final impulse = direction.normalized() * power;
    body.applyLinearImpulse(impulse);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..color = Colors.white;

    // 공의 내부 채우기
    canvas.drawCircle(Offset.zero, radius, paint);

    // 광택 효과 추가
    final highlightPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(-radius * 0.3, -radius * 0.3),
      radius * 0.2,
      highlightPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    try {
      // 공의 속도 제한
      final velocity = body.linearVelocity;
      final speed = velocity.length;

      if (speed > maxSpeed) {
        body.linearVelocity = velocity * (maxSpeed / speed);
      } else if (speed < minSpeed && speed > 0) {
        // 최소 속도 보장 (정지하지 않은 경우만)
        body.linearVelocity = velocity * (minSpeed / speed);
      }

      // 화면 하단 영역 아래로 떨어지면 제거
      final position = body.position;
      final viewportHeight = game.camera.visibleWorldRect.height;
      if (position.y > viewportHeight + radius * 2) {
        removeFromParent();
      }
    } catch (e) {
      // body가 아직 초기화되지 않았을 경우 무시
    }
  }

  // 충돌 시작
  @override
  void beginContact(Object other, Contact contact) {
    // Fixture와 충돌한 경우
    if (other is Fixture) {
      final Object? userData = other.body.userData;

      // 같은 Fixture와 여러 번 접촉하는 것 방지
      if (_contactFixtures.contains(other)) {
        return;
      }

      // 벽돌과 충돌한 경우
      if (userData is Brick) {
        // 벽돌에 데미지 적용
        userData.hit();

        // 접촉 중인 Fixture 추가
        _contactFixtures.add(other);
      }
    }
  }

  // 충돌 종료
  @override
  void endContact(Object other, Contact contact) {
    // Fixture와 충돌이 끝난 경우
    if (other is Fixture) {
      // 접촉 중인 Fixture 목록에서 제거
      _contactFixtures.remove(other);
    }
  }
}
