import 'dart:math';
import 'dart:typed_data';

/// Vector2D에 대한 SIMD 최적화 구현
/// 여러 벡터 연산을 병렬로 수행하는 기능 제공
class Vector2DSIMD {
  /// 벡터 배열에 대한 벡터 덧셈 최적화 (SIMD 방식)
  /// 두 벡터 배열의 같은 인덱스끼리 더함
  static List<double> addVectors(List<double> vectorsA, List<double> vectorsB) {
    if (vectorsA.length != vectorsB.length) {
      throw ArgumentError('Vector arrays must have the same length');
    }

    final result = Float32List(vectorsA.length);

    // 8개씩 병렬 처리 (SIMD 에뮬레이션)
    for (int i = 0; i < vectorsA.length; i += 8) {
      final blockSize = min(8, vectorsA.length - i);
      for (int j = 0; j < blockSize; j++) {
        result[i + j] = vectorsA[i + j] + vectorsB[i + j];
      }
    }

    return result;
  }

  /// 벡터 배열에 대한 벡터 곱셈 최적화 (SIMD 방식)
  /// 벡터 배열의 각 요소에 스칼라 값을 곱함
  static List<double> multiplyVectors(List<double> vectors, double scalar) {
    final result = Float32List(vectors.length);

    // 8개씩 병렬 처리 (SIMD 에뮬레이션)
    for (int i = 0; i < vectors.length; i += 8) {
      final blockSize = min(8, vectors.length - i);
      for (int j = 0; j < blockSize; j++) {
        result[i + j] = vectors[i + j] * scalar;
      }
    }

    return result;
  }

  /// 2D 벡터 배열 최적화 처리
  /// 여러 개의 2D 벡터를 병렬로 처리 (x값들 모음, y값들 모음 형태로 분리)
  static Map<String, List<double>> processVector2DArray(
    List<Map<String, double>> vectors,
  ) {
    final int length = vectors.length;
    final xValues = Float32List(length);
    final yValues = Float32List(length);

    // 벡터 분리
    for (int i = 0; i < length; i++) {
      xValues[i] = vectors[i]['x'] ?? 0.0;
      yValues[i] = vectors[i]['y'] ?? 0.0;
    }

    return {'x': xValues, 'y': yValues};
  }

  /// 벡터 크기(magnitude) 일괄 계산 최적화
  static List<double> magnitudes(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length) {
      throw ArgumentError('X and Y arrays must have the same length');
    }

    final int length = xValues.length;
    final results = Float32List(length);

    // 8개씩 병렬 처리 (SIMD 에뮬레이션)
    for (int i = 0; i < length; i += 8) {
      final blockSize = min(8, length - i);
      for (int j = 0; j < blockSize; j++) {
        final x = xValues[i + j];
        final y = yValues[i + j];
        results[i + j] = sqrt(x * x + y * y);
      }
    }

    return results;
  }

  /// 벡터 정규화 일괄 처리 최적화
  static Map<String, List<double>> normalizeVectors(
    List<double> xValues,
    List<double> yValues,
  ) {
    if (xValues.length != yValues.length) {
      throw ArgumentError('X and Y arrays must have the same length');
    }

    final int length = xValues.length;
    final resultX = Float32List(length);
    final resultY = Float32List(length);

    // 8개씩 병렬 처리 (SIMD 에뮬레이션)
    for (int i = 0; i < length; i += 8) {
      final blockSize = min(8, length - i);
      for (int j = 0; j < blockSize; j++) {
        final x = xValues[i + j];
        final y = yValues[i + j];
        final mag = sqrt(x * x + y * y);

        // 0으로 나누기 방지
        if (mag == 0) {
          resultX[i + j] = 0;
          resultY[i + j] = 0;
        } else {
          resultX[i + j] = x / mag;
          resultY[i + j] = y / mag;
        }
      }
    }

    return {'x': resultX, 'y': resultY};
  }
}
