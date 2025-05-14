import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Colors;

/// 게임 볼 컴포넌트 클래스
class Ball extends BodyComponent {
  final Vector2 position;
  final double radius;
  final Color color;
  final Vector2 initialVelocity;

  /// 생성자
  /// [position] 공의 시작 위치
  /// [radius] 공의 반지름
  /// [color] 공의 색상
  /// [initialVelocity] 초기 발사 속도 벡터
  Ball({
    required this.position,
    this.radius = 0.3,
    this.color = const Color(0xFFFFFFFF),
    required this.initialVelocity,
  });

  @override
  Body createBody() {
    final bodyDef =
        BodyDef()
          ..type = BodyType.dynamic
          ..position = position
          ..bullet =
              true // 빠른 속도에서도 충돌 감지가 정확하게 동작하도록 설정
          ..linearVelocity = initialVelocity;

    final body = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;

    final fixtureDef =
        FixtureDef(shape)
          ..density = 1.0
          ..friction =
              0.0 // 벽에 마찰이 없도록
          ..restitution =
              1.0 // 완전 탄성 충돌
          ..filter.groupIndex = -1; // 다른 공과 충돌하지 않도록 설정

    body.createFixture(fixtureDef);

    return body;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..color = color;

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

    // 현재 속도 확인하여 최소 속도 유지
    final velocity = body.linearVelocity;
    final speed = velocity.length;

    // 최소 속도 보다 느려지면 속도 보정
    final minSpeed = 10.0;
    if (speed < minSpeed) {
      final normalizedVelocity = velocity.normalized();
      body.linearVelocity = normalizedVelocity.scaled(minSpeed);
    }

    // 최대 속도 제한
    final maxSpeed = 20.0;
    if (speed > maxSpeed) {
      final normalizedVelocity = velocity.normalized();
      body.linearVelocity = normalizedVelocity.scaled(maxSpeed);
    }
  }
}
