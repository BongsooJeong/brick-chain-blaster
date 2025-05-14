import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' show Colors;

/// 게임 볼 컴포넌트 클래스
class Ball extends BodyComponent {
  @override
  final Vector2 position;
  final double radius;
  final Color color;
  final Vector2 velocity;

  // 초기 속도를 저장해 두었다가 body 초기화 후 적용
  Vector2? _pendingVelocity;

  /// 생성자
  /// [position] 공의 시작 위치
  /// [radius] 공의 반지름
  /// [color] 공의 색상
  /// [velocity] 초기 발사 속도 벡터
  Ball({
    required this.position,
    this.radius = 0.3,
    this.color = const Color(0xFFFFFFFF),
    required this.velocity,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false; // Forge2D의 기본 그리기를 비활성화하고 직접 렌더링

    // body가 완전히 초기화된 후 대기 중인 속도 적용
    if (_pendingVelocity != null) {
      body.linearVelocity.setFrom(_pendingVelocity!);
      _pendingVelocity = null;
    }
  }

  @override
  Body createBody() {
    final bodyDef =
        BodyDef()
          ..type = BodyType.dynamic
          ..position = position
          ..bullet =
              true // 빠른 속도에서도 충돌 감지가 정확하게 동작하도록 설정
          ..linearVelocity = velocity;

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

  /// 안전하게 공의 속도를 설정하는 메서드
  void setVelocity(Vector2 newVelocity) {
    try {
      // body가 초기화되었으면 직접 속도 설정
      body.linearVelocity.setFrom(newVelocity);
    } catch (e) {
      // body가 아직 초기화되지 않았으면 나중에 적용할 속도로 저장
      _pendingVelocity = newVelocity.clone();
    }
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

    try {
      // 공의 속도 제한
      final velocity = body.linearVelocity;
      final speed = velocity.length;
      const maxSpeed = 20.0;

      if (speed > maxSpeed) {
        body.linearVelocity = velocity * (maxSpeed / speed);
      }
    } catch (e) {
      // body가 아직 초기화되지 않았을 경우 무시
    }
  }
}
