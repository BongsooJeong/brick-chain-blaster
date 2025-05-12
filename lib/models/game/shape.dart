import '../../physics/vector2d.dart';

/// 게임 오브젝트의 형태를 나타내는 기본 추상 클래스
abstract class Shape {
  /// 충돌 감지를 위한 경계 상자 (AABB) 반환
  AABB get boundingBox;

  /// 점이 형태 내부에 있는지 확인
  bool containsPoint(Vector2D point);
}

/// 축 정렬 경계 상자 (Axis-Aligned Bounding Box)
class AABB {
  final Vector2D min;
  final Vector2D max;

  AABB(this.min, this.max);

  /// 두 점으로부터 AABB 생성
  factory AABB.fromPoints(Vector2D p1, Vector2D p2) {
    return AABB(
      Vector2D(p1.x < p2.x ? p1.x : p2.x, p1.y < p2.y ? p1.y : p2.y),
      Vector2D(p1.x > p2.x ? p1.x : p2.x, p1.y > p2.y ? p1.y : p2.y),
    );
  }

  /// 중심점과 크기로부터 AABB 생성
  factory AABB.fromCenter(Vector2D center, Vector2D size) {
    final halfSize = size * 0.5;
    return AABB(center - halfSize, center + halfSize);
  }

  /// AABB의 너비
  double get width => max.x - min.x;

  /// AABB의 높이
  double get height => max.y - min.y;

  /// AABB의 중심점
  Vector2D get center =>
      Vector2D(min.x + (max.x - min.x) / 2, min.y + (max.y - min.y) / 2);

  /// 두 AABB가 겹치는지 확인
  bool overlaps(AABB other) {
    return !(max.x < other.min.x ||
        min.x > other.max.x ||
        max.y < other.min.y ||
        min.y > other.max.y);
  }

  /// 점이 AABB 내부에 있는지 확인
  bool containsPoint(Vector2D point) {
    return point.x >= min.x &&
        point.x <= max.x &&
        point.y >= min.y &&
        point.y <= max.y;
  }
}

/// 원형 충돌체
class Circle implements Shape {
  final Vector2D center;
  final double radius;

  Circle(this.center, this.radius);

  @override
  AABB get boundingBox =>
      AABB.fromCenter(center, Vector2D(radius * 2, radius * 2));

  @override
  bool containsPoint(Vector2D point) {
    final distanceSquared = Vector2D.distanceSquared(center, point);
    return distanceSquared <= radius * radius;
  }

  /// 두 원이 겹치는지 확인
  bool overlaps(Circle other) {
    final distanceSquared = Vector2D.distanceSquared(center, other.center);
    final radiusSum = radius + other.radius;
    return distanceSquared <= radiusSum * radiusSum;
  }
}

/// 다각형 충돌체
class Polygon implements Shape {
  final List<Vector2D> vertices;
  late List<Vector2D> _normals;

  Polygon(this.vertices) {
    _calculateNormals();
  }

  // 다각형의 법선 벡터 계산 (SAT 알고리즘용)
  void _calculateNormals() {
    _normals = [];
    for (int i = 0; i < vertices.length; i++) {
      final current = vertices[i];
      final next = vertices[(i + 1) % vertices.length];
      final edge = next - current;
      // 시계 방향으로 90도 회전하여 법선 벡터 계산
      _normals.add(Vector2D(-edge.y, edge.x).normalized);
    }
  }

  @override
  AABB get boundingBox {
    if (vertices.isEmpty) {
      return AABB(Vector2D.zero(), Vector2D.zero());
    }

    double minX = vertices[0].x;
    double minY = vertices[0].y;
    double maxX = vertices[0].x;
    double maxY = vertices[0].y;

    for (final vertex in vertices) {
      if (vertex.x < minX) minX = vertex.x;
      if (vertex.y < minY) minY = vertex.y;
      if (vertex.x > maxX) maxX = vertex.x;
      if (vertex.y > maxY) maxY = vertex.y;
    }

    return AABB(Vector2D(minX, minY), Vector2D(maxX, maxY));
  }

  @override
  bool containsPoint(Vector2D point) {
    // 광선 투사 알고리즘으로 점이 다각형 내부에 있는지 확인
    bool inside = false;
    for (int i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      if (((vertices[i].y > point.y) != (vertices[j].y > point.y)) &&
          (point.x <
              (vertices[j].x - vertices[i].x) *
                      (point.y - vertices[i].y) /
                      (vertices[j].y - vertices[i].y) +
                  vertices[i].x)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// SAT 알고리즘을 사용하여 두 다각형이 겹치는지 확인
  bool overlapsPolygon(Polygon other) {
    // 이 다각형의 모든 법선 벡터에 대해 SAT 적용
    for (final normal in _normals) {
      double min1 = double.infinity;
      double max1 = double.negativeInfinity;
      double min2 = double.infinity;
      double max2 = double.negativeInfinity;

      // 이 다각형의 모든 점을 법선에 투영
      for (final vertex in vertices) {
        final dot = normal.dot(vertex);
        min1 = min1 < dot ? min1 : dot;
        max1 = max1 > dot ? max1 : dot;
      }

      // 다른 다각형의 모든 점을 동일한 법선에 투영
      for (final vertex in other.vertices) {
        final dot = normal.dot(vertex);
        min2 = min2 < dot ? min2 : dot;
        max2 = max2 > dot ? max2 : dot;
      }

      // 투영이 겹치지 않으면 다각형이 겹치지 않음
      if (max1 < min2 || max2 < min1) {
        return false;
      }
    }

    // 다른 다각형의 모든 법선 벡터에 대해 SAT 적용
    for (final normal in other._normals) {
      double min1 = double.infinity;
      double max1 = double.negativeInfinity;
      double min2 = double.infinity;
      double max2 = double.negativeInfinity;

      // 이 다각형의 모든 점을 법선에 투영
      for (final vertex in vertices) {
        final dot = normal.dot(vertex);
        min1 = min1 < dot ? min1 : dot;
        max1 = max1 > dot ? max1 : dot;
      }

      // 다른 다각형의 모든 점을 동일한 법선에 투영
      for (final vertex in other.vertices) {
        final dot = normal.dot(vertex);
        min2 = min2 < dot ? min2 : dot;
        max2 = max2 > dot ? max2 : dot;
      }

      // 투영이 겹치지 않으면 다각형이 겹치지 않음
      if (max1 < min2 || max2 < min1) {
        return false;
      }
    }

    // 모든 축에서 겹친다면 다각형이 겹침
    return true;
  }
}

/// 사각형 충돌체 (특수 다각형)
class Rectangle extends Polygon {
  final Vector2D position;
  final Vector2D size;

  Rectangle(this.position, this.size)
    : super([
        position,
        Vector2D(position.x + size.x, position.y),
        Vector2D(position.x + size.x, position.y + size.y),
        Vector2D(position.x, position.y + size.y),
      ]);

  /// 중심점과 크기로부터 사각형 생성
  factory Rectangle.fromCenter(Vector2D center, Vector2D size) {
    final halfSize = size * 0.5;
    return Rectangle(center - halfSize, size);
  }

  /// 사각형의 중심점
  Vector2D get center =>
      Vector2D(position.x + size.x / 2, position.y + size.y / 2);

  @override
  AABB get boundingBox => AABB(position, position + size);
}
