import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'physics/physics_engine.dart';
import 'physics/vector2d.dart';
import 'physics/physics_body.dart';
import 'models/game/shape.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '물리 엔진 테스트',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PhysicsDemo(),
    );
  }
}

class PhysicsDemo extends StatefulWidget {
  const PhysicsDemo({super.key});

  @override
  State<PhysicsDemo> createState() => _PhysicsDemoState();
}

class _PhysicsDemoState extends State<PhysicsDemo> {
  late PhysicsEngine engine;
  final List<int> bodyIds = [];
  final math.Random random = math.Random();
  late Timer _timer;

  bool showCollisionDebug = true;
  BroadphaseMethod selectedMethod = BroadphaseMethod.grid;
  bool useStaticCaching = true;
  int objectCount = 50;

  Map<String, dynamic> stats = {};
  int frameCount = 0;
  int lastFrameCount = 0;
  int lastUpdateTime = 0;
  double fps = 0;

  @override
  void initState() {
    super.initState();

    initEngine();

    // 30 FPS로 물리 업데이트 및 UI 리프레시
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      updatePhysics();
      calculateFps();
    });
  }

  void initEngine() {
    // 물리 엔진 초기화
    engine = PhysicsEngine(
      gravity: Vector2D(0, 200), // 중력 설정
      fixedTimeStep: 1 / 60,
      velocityIterations: 8,
      positionIterations: 3,
      substeps: 1,
      debugMode: true,
      broadphaseMethod: selectedMethod,
      useStaticBodyCaching: useStaticCaching,
    );

    // 화면 경계 생성
    createBoundaries();

    // 초기 객체 생성
    createObjects(objectCount);
  }

  void createBoundaries() {
    // 화면 크기 기반 경계 계산
    double width = 400;
    double height = 600;

    // 하단 벽
    final bottomWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(Vector2D(0, 0), Vector2D(width, 20)),
      position: Vector2D(width / 2, height - 10),
      mass: 0,
      restitution: 0.8,
    );

    // 좌측 벽
    final leftWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(Vector2D(0, 0), Vector2D(20, height)),
      position: Vector2D(10, height / 2),
      mass: 0,
      restitution: 0.8,
    );

    // 우측 벽
    final rightWall = PhysicsBody(
      id: -1,
      type: BodyType.static,
      shape: Rectangle(Vector2D(0, 0), Vector2D(20, height)),
      position: Vector2D(width - 10, height / 2),
      mass: 0,
      restitution: 0.8,
    );

    engine.addBody(bottomWall);
    engine.addBody(leftWall);
    engine.addBody(rightWall);
  }

  void createObjects(int count) {
    // 기존 객체 삭제
    for (var id in bodyIds) {
      engine.removeBody(id);
    }
    bodyIds.clear();

    // 새 객체 생성
    for (int i = 0; i < count; i++) {
      // 랜덤 속성 생성
      double size = 10 + random.nextDouble() * 20;
      double x = 50 + random.nextDouble() * 300;
      double y = 50 + random.nextDouble() * 200;

      // 원 또는 사각형 중 랜덤 생성
      Shape shape;
      if (random.nextBool()) {
        shape = Circle(Vector2D(0, 0), size);
      } else {
        shape = Rectangle(Vector2D(0, 0), Vector2D(size * 2, size * 2));
      }

      // 물리 바디 생성
      final body = PhysicsBody(
        id: -1,
        shape: shape,
        position: Vector2D(x, y),
        velocity: Vector2D(
          (random.nextDouble() * 2 - 1) * 100,
          (random.nextDouble() * 2 - 1) * 100,
        ),
        rotation: random.nextDouble() * math.pi * 2,
        angularVelocity: (random.nextDouble() * 2 - 1) * 2,
        mass: size * size * 0.1,
        restitution: 0.7 + random.nextDouble() * 0.3,
        staticFriction: 0.1 + random.nextDouble() * 0.1,
        dynamicFriction: 0.05 + random.nextDouble() * 0.1,
      );

      // 일부 객체는 정적으로 설정
      if (random.nextDouble() < 0.2) {
        body.type = BodyType.static;
      }

      // 물리 엔진에 추가
      final id = engine.addBody(body);
      bodyIds.add(id);
    }
  }

  void updatePhysics() {
    // 물리 시뮬레이션 업데이트
    engine.update(1 / 60);

    // 통계 업데이트
    setState(() {
      if (engine.debugInfo.stats.isNotEmpty) {
        stats = Map.from(engine.debugInfo.stats);
      }
    });

    // 화면 밖으로 나간 객체 처리
    for (final id in List.from(bodyIds)) {
      final body = engine.getBody(id);
      if (body != null) {
        if (body.position.y > 800) {
          engine.removeBody(id);
          bodyIds.remove(id);
        }
      }
    }

    // 객체가 너무 적으면 몇 개 추가
    if (bodyIds.length < objectCount * 0.5) {
      addRandomObjects(5);
    }
  }

  void addRandomObjects(int count) {
    for (int i = 0; i < count; i++) {
      double size = 10 + random.nextDouble() * 20;
      double x = 50 + random.nextDouble() * 300;

      Shape shape;
      if (random.nextBool()) {
        shape = Circle(Vector2D(0, 0), size);
      } else {
        shape = Rectangle(Vector2D(0, 0), Vector2D(size * 2, size * 2));
      }

      final body = PhysicsBody(
        id: -1,
        shape: shape,
        position: Vector2D(x, 30),
        velocity: Vector2D(
          (random.nextDouble() * 2 - 1) * 50,
          random.nextDouble() * 10,
        ),
        rotation: random.nextDouble() * math.pi * 2,
        angularVelocity: (random.nextDouble() * 2 - 1) * 1,
        mass: size * size * 0.1,
        restitution: 0.7 + random.nextDouble() * 0.3,
      );

      final id = engine.addBody(body);
      bodyIds.add(id);
    }
  }

  void calculateFps() {
    frameCount++;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastUpdateTime;

    if (elapsed >= 1000) {
      // 1초마다 FPS 업데이트
      fps = (frameCount - lastFrameCount) * 1000 / elapsed;
      lastFrameCount = frameCount;
      lastUpdateTime = now;
    }
  }

  void resetSimulation() {
    engine.clearBodies();
    bodyIds.clear();

    // 설정 적용
    engine.broadphaseMethod = selectedMethod;
    engine.useStaticBodyCaching = useStaticCaching;

    // 경계 및 객체 재생성
    createBoundaries();
    createObjects(objectCount);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('광범위 충돌 검출 테스트')),
      body: Column(
        children: [
          // 통계 표시 영역
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FPS: ${fps.toStringAsFixed(1)}'),
                Text('총 물체: ${bodyIds.length}개'),
                Text('충돌 쌍: ${stats['pairCount']?.toStringAsFixed(0) ?? 0}개'),
                Text(
                  '충돌 수: ${stats['collisionCount']?.toStringAsFixed(0) ?? 0}개',
                ),
                Text(
                  '광범위 충돌 검출 시간: ${stats['broadphaseTime']?.toStringAsFixed(2) ?? 0}ms',
                ),
              ],
            ),
          ),

          // 컨트롤 패널
          Container(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 방식 선택
                DropdownButton<BroadphaseMethod>(
                  value: selectedMethod,
                  onChanged: (BroadphaseMethod? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedMethod = newValue;
                      });
                      resetSimulation();
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: BroadphaseMethod.grid,
                      child: const Text('그리드 기반'),
                    ),
                    DropdownMenuItem(
                      value: BroadphaseMethod.quadTree,
                      child: const Text('쿼드트리 기반'),
                    ),
                    DropdownMenuItem(
                      value: BroadphaseMethod.aabbTree,
                      child: const Text('AABB 트리 기반'),
                    ),
                  ],
                ),

                // 정적 객체 캐싱
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: useStaticCaching,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            useStaticCaching = value;
                          });
                          resetSimulation();
                        }
                      },
                    ),
                    const Text('정적 객체 캐싱'),
                  ],
                ),

                // 객체 수 슬라이더
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('객체:'),
                    Slider(
                      value: objectCount.toDouble(),
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label: objectCount.toString(),
                      onChanged: (double value) {
                        setState(() {
                          objectCount = value.toInt();
                        });
                      },
                      onChangeEnd: (double value) {
                        resetSimulation();
                      },
                    ),
                  ],
                ),

                // 충돌 디버그 표시
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: showCollisionDebug,
                      onChanged: (bool? value) {
                        setState(() {
                          showCollisionDebug = value ?? false;
                        });
                      },
                    ),
                    const Text('충돌 시각화'),
                  ],
                ),
              ],
            ),
          ),

          // 물리 시뮬레이션 화면
          Expanded(
            child: Container(
              color: Colors.white,
              child: CustomPaint(
                painter: PhysicsPainter(
                  engine: engine,
                  bodyIds: bodyIds,
                  showCollisionDebug: showCollisionDebug,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addRandomObjects(10);
        },
        tooltip: '물체 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PhysicsPainter extends CustomPainter {
  final PhysicsEngine engine;
  final List<int> bodyIds;
  final bool showCollisionDebug;

  PhysicsPainter({
    required this.engine,
    required this.bodyIds,
    this.showCollisionDebug = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 물체 그리기
    for (final id in bodyIds) {
      final body = engine.getBody(id);
      if (body == null) continue;

      // 정적/동적에 따른 색상 설정
      final paint =
          Paint()
            ..style = PaintingStyle.fill
            ..color =
                body.type == BodyType.static
                    ? Colors.grey.withOpacity(0.7)
                    : Colors.blue.withOpacity(0.7);

      // 도형 그리기
      if (body.shape is Circle) {
        final circle = body.shape as Circle;
        canvas.save();
        canvas.translate(body.position.x, body.position.y);
        canvas.rotate(body.rotation);
        canvas.drawCircle(Offset.zero, circle.radius, paint);

        // 회전 표시선
        final linePaint =
            Paint()
              ..color = Colors.red
              ..strokeWidth = 2;
        canvas.drawLine(Offset.zero, Offset(circle.radius, 0), linePaint);

        canvas.restore();
      } else if (body.shape is Rectangle) {
        final rect = body.shape as Rectangle;
        canvas.save();
        canvas.translate(body.position.x, body.position.y);
        canvas.rotate(body.rotation);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: rect.size.x,
            height: rect.size.y,
          ),
          paint,
        );
        canvas.restore();
      }
    }

    // 충돌 시각화
    if (showCollisionDebug) {
      final collisionPaint =
          Paint()
            ..color = Colors.red
            ..strokeWidth = 2;

      for (final collision in engine.debugInfo.collisions) {
        for (final point in collision.contactPoints) {
          canvas.drawCircle(Offset(point.x, point.y), 3, collisionPaint);

          // 충돌 법선 그리기
          canvas.drawLine(
            Offset(point.x, point.y),
            Offset(
              point.x + collision.normal.x * 10,
              point.y + collision.normal.y * 10,
            ),
            collisionPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
