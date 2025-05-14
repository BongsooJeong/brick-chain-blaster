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

  /// 드래그 시작 위치
  Vector2? dragStartPosition;

  /// 길게 눌렀는지 추적 (빠른 발사 취소용)
  bool isLongPress = false;

  /// 드래그 시작 시간
  double dragStartTime = 0;

  /// 애니메이션 타이머
  double _animationTimer = 0.0;

  /// 롱 프레스 감지 딜레이 (초)
  static const longPressDelay = 0.5;

  /// 초기화 생성자
  InputHandler({required this.ballManager});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 조준선 시각화 컴포넌트 생성 및 추가
    aimVisualizer = AimVisualizer(
      startPosition: ballManager.firingPosition,
      shootCallback: _shoot,
      cancelCallback: _cancelFiring,
      ballManager: ballManager,
    );
    await add(aimVisualizer);

    print('InputHandler 초기화 완료');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 애니메이션 타이머 업데이트
    _animationTimer += dt;

    // 드래그 중이면 롱 프레스 감지
    if (isDragging && !isLongPress) {
      final currentTime = _animationTimer;
      final elapsedTime = currentTime - dragStartTime;

      // 롱 프레스 감지
      if (elapsedTime > longPressDelay) {
        isLongPress = true;
        print('롱 프레스 감지, 발사 취소 가능');
      }
    }
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

    // 드래그 시작 시간 기록
    dragStartTime = _animationTimer;
    isLongPress = false;

    // 시작 위치가 발사점에 가까운지 확인
    final worldPosition = _convertPositionToWorld(touchPosition);
    final distance = (worldPosition - ballManager.firingPosition).length;

    // 드래그 시작 위치 저장
    dragStartPosition = worldPosition.clone();

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

    // 길게 눌렀는지 확인하고 시각적 피드백 제공
    if (isLongPress) {
      // 롱 프레스 감지 시 발사 취소 준비 상태로 전환
      // 필요한 시각적 처리 추가 가능
    }

    aimVisualizer.onDragUpdate(worldPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (!isDragging || ballManager.isFiring) return;

    print('Drag 종료, 발사 시작');
    isDragging = false;
    dragStartPosition = null;

    // 롱 프레스 플래그가 설정되어 있으면 발사하지 않음
    if (isLongPress) {
      aimVisualizer.onDragCancel();
      return;
    }

    aimVisualizer.onDragEnd();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (!isDragging) return;

    print('Drag 취소');
    isDragging = false;
    dragStartPosition = null;
    aimVisualizer.onDragCancel();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (ballManager.isFiring) return;

    // 탭 위치를 월드 좌표로 변환
    final touchPosition = event.localPosition;
    final worldPosition = _convertPositionToWorld(touchPosition);

    print('Tap: $worldPosition');

    // 발사 위치 근처에서 탭하면 즉시 위쪽 방향으로 발사
    final distance = (worldPosition - ballManager.firingPosition).length;
    if (distance < 2.0) {
      // 위쪽 방향 벡터 (y가 음수인 이유는 화면 좌표계에서 아래가 양수 방향)
      final upDirection = Vector2(0, -1);
      _shoot(upDirection);
    }
  }

  /// 화면 좌표를 월드 좌표로 변환
  Vector2 _convertPositionToWorld(Vector2 screenPosition) {
    // 화면 좌표를 월드 좌표로 변환 (Flame 1.28.1 호환 방식)
    final position = screenPosition.clone();
    final zoom = gameRef.camera.viewfinder.zoom;
    final cameraPosition = gameRef.camera.viewfinder.position;

    // 카메라의 실제 크기와 화면(캔버스) 크기
    final canvasSize = gameRef.canvasSize;

    // 화면 중앙 좌표
    final centerX = canvasSize.x / 2;
    final centerY = canvasSize.y / 2;

    // 화면 좌표 -> 월드 좌표 변환
    final worldX = (position.x - centerX) / zoom + cameraPosition.x;
    final worldY = (position.y - centerY) / zoom + cameraPosition.y;

    return Vector2(worldX, worldY);
  }

  /// 공 발사 메서드
  void _shoot(Vector2 direction) {
    if (ballManager.isFiring) return;

    print('공 발사 요청: 방향 = $direction');

    // 방향이 너무 짧으면 발사하지 않음
    if (direction.length < 0.1) return;

    // 공 발사 시작
    ballManager.fireBall(direction);
  }

  /// 발사 취소 메서드
  void _cancelFiring() {
    print('발사 취소');
    // 추가 취소 로직 (UI 피드백 등)
  }
}
