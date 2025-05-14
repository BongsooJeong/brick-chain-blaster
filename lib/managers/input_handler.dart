import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:brick_chain_blaster/game/brick_chain_game.dart';
import 'package:brick_chain_blaster/managers/ball_manager.dart';
import 'package:brick_chain_blaster/components/aim_visualizer.dart';

/// 게임 입력 처리 관리 클래스
class InputHandler extends Component
    with HasGameRef<BrickChainGame>, DragCallbacks, TapCallbacks {
  /// 공 관리자 참조
  late final BallManager ballManager;

  /// 조준 시각화 컴포넌트 참조
  late final AimVisualizer aimVisualizer;

  /// 드래그 중인지 상태
  bool isDragging = false;

  /// 초기화 생성자
  InputHandler({required this.ballManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 조준선 시각화 컴포넌트 생성 및 추가
    aimVisualizer = AimVisualizer(
      startPosition: ballManager.firingPosition,
      shootCallback: _shoot,
    );
    await add(aimVisualizer);

    print('InputHandler 초기화 완료');
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // 항상 입력을 받도록 전체 화면 영역 처리
    return true;
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (ballManager.isFiring) return;

    final touchPosition = event.localPosition;
    print('Drag 시작: $touchPosition');

    // 시작 위치가 발사점에 가까운지 확인
    final worldPosition = _convertPositionToWorld(touchPosition);
    final distance = (worldPosition - ballManager.firingPosition).length;

    // 발사 위치 근처에서만 드래그 시작 허용 (여유있게 설정)
    if (distance < 2.0) {
      isDragging = true;
      aimVisualizer.onDragStart(worldPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging || ballManager.isFiring) return;

    final touchPosition = event.localEndPosition;
    final worldPosition = _convertPositionToWorld(touchPosition);
    aimVisualizer.onDragUpdate(worldPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!isDragging || ballManager.isFiring) return;

    print('Drag 종료, 발사 시작');
    isDragging = false;
    aimVisualizer.onDragEnd();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (ballManager.isFiring) return;

    // 탭 위치를 월드 좌표로 변환
    final touchPosition = event.localPosition;
    final worldPosition = _convertPositionToWorld(touchPosition);

    print('Tap: $worldPosition');

    // 여기에 탭 기능 추가 가능 (예: 디버그 정보 표시)
  }

  /// 화면 좌표를 월드 좌표로 변환
  Vector2 _convertPositionToWorld(Vector2 screenPosition) {
    // Flame 1.28.1에서 고정 해상도 뷰포트 사용 시
    // 직접 변환을 계산하는 것이 더 안정적입니다
    final position = screenPosition.clone();
    final zoom = gameRef.camera.viewfinder.zoom;
    final cameraPosition = gameRef.camera.viewfinder.position;
    final size = gameRef.size;
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    position.x = (position.x - centerX) / zoom + cameraPosition.x;
    position.y = (position.y - centerY) / zoom + cameraPosition.y;
    return position;
  }

  /// 공 발사 메서드
  void _shoot(Vector2 direction) {
    if (ballManager.isFiring) return;

    print('공 발사 요청: 방향 = $direction');

    // 방향이 너무 짧으면 발사하지 않음
    if (direction.length < 0.1) return;

    // 공 발사 시작
    ballManager.startFiring(direction);
  }
}
