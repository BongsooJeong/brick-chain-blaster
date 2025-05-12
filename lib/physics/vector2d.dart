import 'dart:math';

/// 2D 벡터 클래스 - 물리 계산에 필요한 기본 수학적 표현
class Vector2D {
  double x;
  double y;

  Vector2D(this.x, this.y);

  /// 영벡터 생성
  Vector2D.zero() : x = 0, y = 0;

  /// 복사 생성자
  Vector2D.copy(Vector2D other) : x = other.x, y = other.y;

  /// 극좌표 형식으로 벡터 생성 (각도는 라디안)
  factory Vector2D.fromAngle(double angle, double magnitude) {
    return Vector2D(
      magnitude * cos(angle),
      magnitude * sin(angle),
    );
  }

  /// 벡터 더하기
  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);

  /// 벡터 빼기
  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);

  /// 벡터 스칼라곱
  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);

  /// 벡터 스칼라 나누기
  Vector2D operator /(double scalar) => Vector2D(x / scalar, y / scalar);

  /// 벡터 부정
  Vector2D operator -() => Vector2D(-x, -y);

  /// 벡터 크기 (길이)
  double get magnitude => sqrt(x * x + y * y);

  /// 벡터 크기의 제곱 (계산 최적화용)
  double get magnitudeSquared => x * x + y * y;

  /// 벡터 각도 (라디안)
  double get angle => atan2(y, x);

  /// 정규화된 벡터 (단위 벡터)
  Vector2D get normalized {
    final mag = magnitude;
    if (mag == 0) return Vector2D.zero();
    return Vector2D(x / mag, y / mag);
  }

  /// 벡터 내적
  double dot(Vector2D other) => x * other.x + y * other.y;

  /// 벡터 외적의 z값
  double cross(Vector2D other) => x * other.y - y * other.x;

  /// 벡터 회전 (라디안)
  Vector2D rotate(double angle) {
    final cos_a = cos(angle);
    final sin_a = sin(angle);
    return Vector2D(
      x * cos_a - y * sin_a,
      x * sin_a + y * cos_a,
    );
  }

  /// 두 벡터 사이의 거리
  static double distance(Vector2D a, Vector2D b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// 두 벡터 사이의 거리 제곱 (계산 최적화용)
  static double distanceSquared(Vector2D a, Vector2D b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  /// 벡터 선형 보간
  static Vector2D lerp(Vector2D a, Vector2D b, double t) {
    return Vector2D(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
  }

  /// 직렬화를 위한 Map 변환
  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  /// Map에서 벡터 생성
  factory Vector2D.fromJson(Map<String, dynamic> json) {
    return Vector2D(json['x'] as double, json['y'] as double);
  }

  @override
  String toString() => 'Vector2D($x, $y)';
}