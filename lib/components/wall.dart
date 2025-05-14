import 'dart:ui';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';

/// 게임 벽 컴포넌트 클래스
class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;
  final Color color;
  final double thickness;

  /// 생성자
  /// [start] 시작점
  /// [end] 끝점
  /// [color] 벽의 색상
  /// [thickness] 벽의 두께
  Wall({
    required this.start,
    required this.end,
    this.color = const Color(0xFF666666),
    this.thickness = 0.1,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = false; // Forge2D의 기본 그리기를 비활성화하고 직접 렌더링
  }

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0.3, restitution: 0.8);

    final bodyDef = BodyDef(position: Vector2.zero(), type: BodyType.static);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = thickness
          ..style = PaintingStyle.stroke;

    canvas.drawLine(start.toOffset(), end.toOffset(), paint);
  }
}
