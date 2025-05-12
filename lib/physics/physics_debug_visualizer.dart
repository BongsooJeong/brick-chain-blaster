import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'vector2d.dart';
import 'physics_body.dart';
import 'physics_debug.dart';
import 'collision.dart';
import '../models/game/shape.dart';

/// 디버그 시각화 옵션
class DebugVisualizerOptions {
  /// 물리 바디 라인 색상
  final Color bodyColor;

  /// 정적 바디 라인 색상
  final Color staticBodyColor;

  /// 키네마틱 바디 라인 색상
  final Color kinematicBodyColor;

  /// 충돌 접촉점 색상
  final Color contactColor;

  /// 속도 벡터 색상
  final Color velocityColor;

  /// 힘 벡터 색상
  final Color forceColor;

  /// 경계 상자(AABB) 색상
  final Color aabbColor;

  /// 선택된 바디 색상
  final Color selectedBodyColor;

  /// 속도 벡터 스케일
  final double velocityScale;

  /// 힘 벡터 스케일
  final double forceScale;

  /// 경계 상자 표시 여부
  final bool showAABB;

  /// 속도 벡터 표시 여부
  final bool showVelocity;

  /// 힘 벡터 표시 여부
  final bool showForce;

  /// 각속도 표시 여부
  final bool showAngularVelocity;

  /// 접촉점 표시 여부
  final bool showContacts;

  /// 바디 ID 표시 여부
  final bool showBodyId;

  /// 바디 좌표 표시 여부
  final bool showBodyCoords;

  /// 좌표계 그리드 표시 여부
  final bool showGrid;

  /// 그리드 사이즈
  final double gridSize;

  /// 그리드 색상
  final Color gridColor;

  /// 생성자
  const DebugVisualizerOptions({
    this.bodyColor = Colors.green,
    this.staticBodyColor = Colors.grey,
    this.kinematicBodyColor = Colors.blue,
    this.contactColor = Colors.red,
    this.velocityColor = Colors.yellow,
    this.forceColor = Colors.purple,
    this.aabbColor = const Color(0x44FFFFFF),
    this.selectedBodyColor = Colors.orange,
    this.velocityScale = 0.1,
    this.forceScale = 0.01,
    this.showAABB = true,
    this.showVelocity = true,
    this.showForce = true,
    this.showAngularVelocity = true,
    this.showContacts = true,
    this.showBodyId = true,
    this.showBodyCoords = false,
    this.showGrid = true,
    this.gridSize = 50.0,
    this.gridColor = const Color(0x22FFFFFF),
  });
}

/// 물리 엔진 시각화 기능 제공 클래스
class PhysicsDebugVisualizer {
  /// 시각화 옵션
  final DebugVisualizerOptions options;

  /// 텍스트 스타일 - 바디 ID
  final TextStyle _idTextStyle = const TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  /// 텍스트 스타일 - 바디 좌표
  final TextStyle _coordTextStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 8,
  );

  /// 바디 라인 두께
  final double _bodyStrokeWidth = 1.5;

  /// 벡터 라인 두께
  final double _vectorStrokeWidth = 1.0;

  /// AABB 라인 두께
  final double _aabbStrokeWidth = 0.5;

  /// 화면 중심 좌표
  Vector2D _screenCenter = Vector2D(0, 0);

  /// 카메라 확대/축소 비율
  double _zoom = 1.0;

  /// 현재 선택된 바디 ID
  int? _selectedBodyId;

  /// 생성자
  PhysicsDebugVisualizer({this.options = const DebugVisualizerOptions()});

  /// 화면 중심 설정
  void setScreenCenter(double x, double y) {
    _screenCenter = Vector2D(x, y);
  }

  /// 줌 레벨 설정
  void setZoom(double zoom) {
    _zoom = math.max(0.1, zoom);
  }

  /// 바디 선택
  void selectBody(int? bodyId) {
    _selectedBodyId = bodyId;
  }

  /// 물리 월드 시각화 핵심 메서드
  void render(
    Canvas canvas,
    Size size,
    List<PhysicsBody> bodies,
    List<Collision> collisions,
    PhysicsDebugInfo debugInfo,
  ) {
    // 캔버스 준비
    canvas.save();

    // 캔버스를 화면 중앙으로 이동하고 확대/축소 적용
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(_zoom, _zoom);
    canvas.translate(-_screenCenter.x, -_screenCenter.y);

    // 그리드 그리기
    if (options.showGrid) {
      _drawGrid(canvas, size);
    }

    // 경계 상자 그리기
    if (options.showAABB) {
      for (final body in bodies) {
        _drawAABB(canvas, body);
      }
    }

    // 바디 그리기
    for (final body in bodies) {
      _drawBody(canvas, body);
    }

    // 충돌 접촉점 그리기
    if (options.showContacts) {
      _drawCollisionContacts(canvas, collisions);
    }

    // 선택된 바디 주변에 특별 효과 그리기
    if (_selectedBodyId != null) {
      final selectedBody = bodies.firstWhere(
        (b) => b.id == _selectedBodyId,
        orElse: () => null as PhysicsBody?,
      );

      _drawSelectedBodyHighlight(canvas, selectedBody);
    }

    // 디버그 통계 표시
    _drawDebugStats(canvas, size, debugInfo);

    // 캔버스 복원
    canvas.restore();
  }

  /// 그리드 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = options.gridColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // 화면에 표시될 그리드 경계 계산
    final screenHalfWidth = size.width / (2 * _zoom);
    final screenHalfHeight = size.height / (2 * _zoom);

    final left = _screenCenter.x - screenHalfWidth;
    final right = _screenCenter.x + screenHalfWidth;
    final top = _screenCenter.y - screenHalfHeight;
    final bottom = _screenCenter.y + screenHalfHeight;

    // 그리드 라인 시작점 계산
    final startX = (left ~/ options.gridSize) * options.gridSize;
    final startY = (top ~/ options.gridSize) * options.gridSize;

    // 세로 그리드 라인
    for (double x = startX; x <= right; x += options.gridSize) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }

    // 가로 그리드 라인
    for (double y = startY; y <= bottom; y += options.gridSize) {
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }

    // 축 강조
    final axisPaint =
        Paint()
          ..color = options.gridColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    // X축
    canvas.drawLine(Offset(left, 0), Offset(right, 0), axisPaint);

    // Y축
    canvas.drawLine(Offset(0, top), Offset(0, bottom), axisPaint);
  }

  /// AABB 경계 상자 그리기
  void _drawAABB(Canvas canvas, PhysicsBody body) {
    final paint =
        Paint()
          ..color = options.aabbColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _aabbStrokeWidth;

    final aabb = body.aabb;

    // AABB 경계 상자 그리기 방식 수정
    final rect = Rect.fromLTRB(
      body.position.x + aabb.min.x,
      body.position.y + aabb.min.y,
      body.position.x + aabb.max.x,
      body.position.y + aabb.max.y,
    );

    canvas.drawRect(rect, paint);
  }

  /// 물리 바디 그리기
  void _drawBody(Canvas canvas, PhysicsBody body) {
    // 바디 타입에 따른 색상 선택
    Color bodyColor;
    switch (body.type) {
      case BodyType.static:
        bodyColor = options.staticBodyColor;
        break;
      case BodyType.kinematic:
        bodyColor = options.kinematicBodyColor;
        break;
      case BodyType.dynamic:
        bodyColor = options.bodyColor;
        break;
      default:
        bodyColor = options.bodyColor;
    }

    // 선택된 바디인 경우 색상 변경
    if (_selectedBodyId == body.id) {
      bodyColor = options.selectedBodyColor;
    }

    final paint =
        Paint()
          ..color = bodyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _bodyStrokeWidth;

    // 캔버스 상태 저장
    canvas.save();

    // 바디 위치로 이동하고 회전 적용
    canvas.translate(body.position.x, body.position.y);
    canvas.rotate(body.rotation);

    // 셰이프 그리기
    _drawShape(canvas, body.shape, paint);

    // 캔버스 복원
    canvas.restore();

    // 속도 벡터 그리기
    if (options.showVelocity &&
        !body.velocity.magnitude.isNaN &&
        body.velocity.magnitudeSquared > 0.001) {
      final velocityPaint =
          Paint()
            ..color = options.velocityColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = _vectorStrokeWidth;

      _drawVector(
        canvas,
        body.position,
        body.velocity * options.velocityScale,
        velocityPaint,
      );
    }

    // 힘 벡터 그리기
    if (options.showForce &&
        !body.force.magnitude.isNaN &&
        body.force.magnitudeSquared > 0.001) {
      final forcePaint =
          Paint()
            ..color = options.forceColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = _vectorStrokeWidth;

      _drawVector(
        canvas,
        body.position,
        body.force * options.forceScale,
        forcePaint,
      );
    }

    // 바디 ID 그리기
    if (options.showBodyId) {
      final textPainter = TextPainter(
        text: TextSpan(text: '${body.id}', style: _idTextStyle),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          body.position.x - textPainter.width / 2,
          body.position.y - textPainter.height / 2,
        ),
      );
    }

    // 바디 좌표 그리기
    if (options.showBodyCoords) {
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '(${body.position.x.toStringAsFixed(1)}, ${body.position.y.toStringAsFixed(1)})',
          style: _coordTextStyle,
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(body.position.x - textPainter.width / 2, body.position.y + 10),
      );
    }
  }

  /// 벡터 그리기
  void _drawVector(
    Canvas canvas,
    Vector2D start,
    Vector2D vector,
    Paint paint,
  ) {
    if (vector.magnitudeSquared < 0.0001) return;

    final end = start + vector;

    // 라인 그리기
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), paint);

    // 화살표 그리기
    final headSize = 5.0 / _zoom;
    final direction = vector.normalized;
    final perpendicular = Vector2D(-direction.y, direction.x);

    final arrowHead1 =
        end - direction * headSize + perpendicular * (headSize * 0.5);
    final arrowHead2 =
        end - direction * headSize - perpendicular * (headSize * 0.5);

    final path =
        Path()
          ..moveTo(end.x, end.y)
          ..lineTo(arrowHead1.x, arrowHead1.y)
          ..lineTo(arrowHead2.x, arrowHead2.y)
          ..close();

    final arrowPaint =
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;

    canvas.drawPath(path, arrowPaint);
  }

  /// 셰이프 그리기
  void _drawShape(Canvas canvas, Shape shape, Paint paint) {
    switch (shape.type) {
      case ShapeType.circle:
        final radius = shape.radius;
        canvas.drawCircle(Offset.zero, radius, paint);

        // 회전 표시선 추가
        canvas.drawLine(Offset.zero, Offset(radius, 0), paint);
        break;

      case ShapeType.box:
        final width = shape.width;
        final height = shape.height;

        final rect = Rect.fromLTRB(
          -width / 2,
          -height / 2,
          width / 2,
          height / 2,
        );

        canvas.drawRect(rect, paint);
        break;

      case ShapeType.polygon:
        final vertices = shape.vertices;
        if (vertices.isEmpty) return;

        final path = Path()..moveTo(vertices[0].x, vertices[0].y);

        for (int i = 1; i < vertices.length; i++) {
          path.lineTo(vertices[i].x, vertices[i].y);
        }

        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  /// 충돌 접촉점 그리기
  void _drawCollisionContacts(Canvas canvas, List<Collision> collisions) {
    final paint =
        Paint()
          ..color = options.contactColor
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0;

    for (final collision in collisions) {
      // contactPoints 필드 사용
      for (final contact in collision.contactPoints) {
        canvas.drawCircle(Offset(contact.x, contact.y), 3.0 / _zoom, paint);

        // 충돌 법선 표시
        final normalEnd = contact + collision.normal * 10.0;

        final normalPaint =
            Paint()
              ..color = options.contactColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;

        canvas.drawLine(
          Offset(contact.x, contact.y),
          Offset(normalEnd.x, normalEnd.y),
          normalPaint,
        );
      }
    }
  }

  /// 선택된 바디 강조 효과
  void _drawSelectedBodyHighlight(Canvas canvas, PhysicsBody body) {
    final paint =
        Paint()
          ..color = options.selectedBodyColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _bodyStrokeWidth * 2;

    // 캔버스 상태 저장
    canvas.save();

    // 바디 위치로 이동하고 회전 적용
    canvas.translate(body.position.x, body.position.y);
    canvas.rotate(body.rotation);

    // 셰이프 강조 효과
    _drawShape(canvas, body.shape, paint);

    // 캔버스 복원
    canvas.restore();
  }

  /// 디버그 통계 표시
  void _drawDebugStats(Canvas canvas, Size size, PhysicsDebugInfo debugInfo) {
    // 원래 변환 상태로 복원
    canvas.restore();
    canvas.save();

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontFamily: 'Monospace',
    );

    // FPS
    final fps = debugInfo.stats['fps']?.toStringAsFixed(1) ?? 'N/A';
    final bodyCount =
        debugInfo.stats['totalBodyCount']?.toInt().toString() ?? 'N/A';
    final activeCount =
        debugInfo.stats['activeBodyCount']?.toInt().toString() ?? 'N/A';
    final collisionCount =
        debugInfo.stats['collisionCount']?.toInt().toString() ?? 'N/A';

    final statText =
        'FPS: $fps | Bodies: $bodyCount | Active: $activeCount | Collisions: $collisionCount';

    final textPainter = TextPainter(
      text: TextSpan(text: statText, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));
  }
}
