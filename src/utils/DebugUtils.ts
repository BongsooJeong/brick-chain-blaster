import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class DebugManager {
  private scene: Phaser.Scene;
  private debugText: Phaser.GameObjects.Text;
  private fpsCounter: Phaser.GameObjects.Text;
  private performanceMetrics: Phaser.GameObjects.Text;
  private isDebugMode: boolean = false;
  
  // 충돌 시각화 관련 변수
  private collisionGraphics: Phaser.GameObjects.Graphics;
  private velocityVectors: Phaser.GameObjects.Graphics;
  private collisionPoints: { x: number, y: number, time: number }[] = [];
  private readonly MAX_COLLISION_POINTS = 5; // 최대 표시할 충돌 포인트 수
  private readonly COLLISION_POINT_LIFETIME = 1000; // 충돌 포인트 표시 지속 시간 (ms)
  
  // 성능 모니터링 변수
  private frameTimeHistory: number[] = [];
  private readonly FRAME_HISTORY_LENGTH = 60; // 60프레임(약 1초) 동안의 기록 유지
  private lastUpdateTime: number = 0;
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    
    // 디버그 텍스트 초기화
    this.debugText = scene.add.text(
      16, 
      scene.cameras.main.height - 80, 
      '', 
      {
        fontFamily: 'Courier',
        fontSize: '14px',
        color: '#00ff00',
        backgroundColor: '#00000055'
      }
    );
    this.debugText.setVisible(false);
    this.debugText.setDepth(1000); // UI가 항상 위에 표시되도록
    
    // FPS 카운터 초기화
    this.fpsCounter = scene.add.text(
      16, 
      scene.cameras.main.height - 40, 
      '', 
      {
        fontFamily: 'Courier',
        fontSize: '14px',
        color: '#00ff00',
        backgroundColor: '#00000055'
      }
    );
    this.fpsCounter.setVisible(false);
    this.fpsCounter.setDepth(1000);
    
    // 성능 메트릭 텍스트 초기화
    this.performanceMetrics = scene.add.text(
      scene.cameras.main.width - 16,
      50,
      '',
      {
        fontFamily: 'Courier',
        fontSize: '12px',
        color: '#ffff00',
        backgroundColor: '#00000077',
        align: 'right'
      }
    );
    this.performanceMetrics.setOrigin(1, 0);
    this.performanceMetrics.setVisible(false);
    this.performanceMetrics.setDepth(1000);
    
    // 디버그 모드 정보 텍스트
    const debugHelpText = scene.add.text(
      scene.cameras.main.width - 16, 
      scene.cameras.main.height - 16, 
      'D키: 디버그 토글', 
      {
        fontFamily: 'Arial',
        fontSize: '12px',
        color: '#aaaaaa'
      }
    ).setOrigin(1, 1);
    
    // 충돌 시각화 그래픽 초기화
    this.collisionGraphics = scene.add.graphics();
    this.collisionGraphics.setVisible(false);
    
    // 속도 벡터 시각화 그래픽 초기화
    this.velocityVectors = scene.add.graphics();
    this.velocityVectors.setVisible(false);
    
    // 디버그 키 매핑 추가
    this.setupDebugKeyMappings();
  }
  
  // 디버그 키 매핑 설정
  private setupDebugKeyMappings(): void {
    // P 키 - 물리 엔진 일시 정지/재개
    this.scene.input.keyboard?.addKey('P').on('down', () => {
      if (!this.isDebugMode) return;
      
      const physics = this.scene.physics as Phaser.Physics.Arcade.ArcadePhysics;
      physics.world.isPaused = !physics.world.isPaused;
      console.log(`물리 엔진: ${physics.world.isPaused ? '일시 정지됨' : '실행 중'}`);
    });
  }
  
  // 디버그 모드 토글
  public toggleDebugMode(): void {
    this.isDebugMode = !this.isDebugMode;
    
    // 물리 디버그 토글
    this.scene.physics.world.drawDebug = this.isDebugMode;
    
    // debugGraphic이 존재할 때만 clear 호출
    if (this.scene.physics.world.debugGraphic) {
      this.scene.physics.world.debugGraphic.clear();
    }
    
    // 디버그 UI 요소 가시성 토글
    this.debugText.setVisible(this.isDebugMode);
    this.fpsCounter.setVisible(this.isDebugMode);
    this.performanceMetrics.setVisible(this.isDebugMode);
    this.collisionGraphics.setVisible(this.isDebugMode);
    this.velocityVectors.setVisible(this.isDebugMode);
    
    console.log(`디버그 모드: ${this.isDebugMode ? '켜짐' : '꺼짐'}`);
  }
  
  // 공 충돌 위치 기록
  public recordCollision(x: number, y: number, velocityX: number, velocityY: number): void {
    if (!this.isDebugMode) return;
    
    // 충돌 포인트 기록
    this.collisionPoints.push({
      x,
      y,
      time: this.scene.time.now
    });
    
    // 최대 표시 개수 제한
    if (this.collisionPoints.length > this.MAX_COLLISION_POINTS) {
      this.collisionPoints.shift();
    }
    
    // 충돌 방향 표시 (입사각 및 반사각 시각화)
    this.drawCollisionVector(x, y, velocityX, velocityY);
  }
  
  // 충돌 벡터 그리기
  private drawCollisionVector(x: number, y: number, vx: number, vy: number): void {
    // 충돌 그래픽이 존재하지 않으면 반환
    if (!this.collisionGraphics || !this.isDebugMode) return;
    
    // 입사 벡터(빨간색)과 예상 반사 벡터(녹색) 그리기
    this.collisionGraphics.clear();
    
    // 입사 벡터 (이전 방향)
    const vectorScale = 0.2; // 벡터 스케일 (속도에 비례)
    this.collisionGraphics.lineStyle(2, 0xff0000);
    this.collisionGraphics.beginPath();
    this.collisionGraphics.moveTo(x, y);
    this.collisionGraphics.lineTo(x - vx * vectorScale, y - vy * vectorScale);
    this.collisionGraphics.strokePath();
    
    // 반사 벡터 (예상 방향)
    this.collisionGraphics.lineStyle(2, 0x00ff00);
    this.collisionGraphics.beginPath();
    this.collisionGraphics.moveTo(x, y);
    this.collisionGraphics.lineTo(x + vx * vectorScale, y - vy * vectorScale); // Y방향 반전 (단순 반사 가정)
    this.collisionGraphics.strokePath();
    
    // 충돌 포인트 표시
    this.collisionGraphics.fillStyle(0xffff00);
    this.collisionGraphics.fillCircle(x, y, 4);
  }
  
  // 디버그 텍스트 업데이트
  public updateDebugInfo(ball: Phaser.Physics.Arcade.Sprite, time: number, delta: number): void {
    if (!this.isDebugMode) return;
    
    // 프레임 시간 기록 (성능 측정용)
    this.frameTimeHistory.push(delta);
    if (this.frameTimeHistory.length > this.FRAME_HISTORY_LENGTH) {
      this.frameTimeHistory.shift();
    }
    
    // FPS 업데이트
    const fps = Math.round(this.scene.game.loop.actualFps);
    this.fpsCounter.setText(`FPS: ${fps}`);
    
    // 공 정보 업데이트
    if (ball.body) {
      const velocity = ball.body.velocity;
      const speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
      
      this.debugText.setText(
        `공 속도: X=${Math.round(velocity.x)}, Y=${Math.round(velocity.y)}\n` +
        `공 위치: X=${Math.round(ball.x)}, Y=${Math.round(ball.y)}\n` +
        `속력: ${Math.round(speed)}, 최대: ${PHYSICS_CONSTANTS.BALL.MAX_VELOCITY}`
      );
      
      // 속도 벡터 시각화
      this.drawVelocityVector(ball);
    }
    
    // 성능 메트릭 업데이트 (매 10프레임마다)
    if (time - this.lastUpdateTime > 100) { // 약 100ms마다 업데이트
      this.updatePerformanceMetrics();
      this.lastUpdateTime = time;
    }
    
    // 만료된 충돌 포인트 제거
    this.collisionPoints = this.collisionPoints.filter(
      point => (time - point.time) < this.COLLISION_POINT_LIFETIME
    );
    
    // 충돌 포인트 시각화 업데이트
    this.updateCollisionPoints();
  }
  
  // 성능 메트릭 업데이트
  private updatePerformanceMetrics(): void {
    // 프레임 시간 통계 계산
    const frameTimesMs = this.frameTimeHistory;
    const avgFrameTime = frameTimesMs.reduce((sum, time) => sum + time, 0) / Math.max(1, frameTimesMs.length);
    const minFrameTime = Math.min(...frameTimesMs);
    const maxFrameTime = Math.max(...frameTimesMs);
    
    // 물리 엔진 정보
    const physics = this.scene.physics as Phaser.Physics.Arcade.ArcadePhysics;
    const physicsEnabled = this.scene.physics.world.isPaused === false;
    const physicsStepRate = 1000 / 60; // Phaser는 기본적으로 60Hz의 물리 시뮬레이션
    
    // 장면 객체 수
    const totalObjects = this.scene.children.length;
    const activeObjects = this.scene.children.getAll().filter(obj => obj.active).length;
    
    // 메모리 정보 (JavaScript 메모리 정보는 제한적으로만 접근 가능)
    const memoryInfo = (performance as any).memory ? 
      `메모리: ${Math.round((performance as any).memory.usedJSHeapSize / 1024 / 1024)}MB` : '';
    
    this.performanceMetrics.setText(
      `프레임 시간: ${avgFrameTime.toFixed(2)}ms 평균\n` +
      `⤷ ${minFrameTime.toFixed(2)}ms 최소, ${maxFrameTime.toFixed(2)}ms 최대\n` +
      `물리 엔진: ${physicsEnabled ? '활성화' : '비활성화'}, ${physicsStepRate}ms 스텝\n` +
      `객체 수: ${activeObjects}/${totalObjects} 활성화\n` +
      `${memoryInfo}`
    );
  }
  
  // 속도 벡터 그리기
  private drawVelocityVector(ball: Phaser.Physics.Arcade.Sprite): void {
    if (!ball.body || !this.velocityVectors || !this.isDebugMode) return;
    
    this.velocityVectors.clear();
    
    // 현재 속도 방향 표시 (파란색)
    const vx = ball.body.velocity.x;
    const vy = ball.body.velocity.y;
    const vectorScale = 0.2; // 벡터 스케일 (속도에 비례)
    
    this.velocityVectors.lineStyle(2, 0x00ffff);
    this.velocityVectors.beginPath();
    this.velocityVectors.moveTo(ball.x, ball.y);
    this.velocityVectors.lineTo(ball.x + vx * vectorScale, ball.y + vy * vectorScale);
    this.velocityVectors.strokePath();
    
    // 방향 화살표 표시
    const angle = Math.atan2(vy, vx);
    const arrowSize = 10;
    const arrowX = ball.x + vx * vectorScale;
    const arrowY = ball.y + vy * vectorScale;
    
    this.velocityVectors.lineStyle(2, 0x00ffff);
    this.velocityVectors.beginPath();
    this.velocityVectors.moveTo(arrowX, arrowY);
    this.velocityVectors.lineTo(
      arrowX - arrowSize * Math.cos(angle - Math.PI / 6),
      arrowY - arrowSize * Math.sin(angle - Math.PI / 6)
    );
    this.velocityVectors.moveTo(arrowX, arrowY);
    this.velocityVectors.lineTo(
      arrowX - arrowSize * Math.cos(angle + Math.PI / 6),
      arrowY - arrowSize * Math.sin(angle + Math.PI / 6)
    );
    this.velocityVectors.strokePath();
  }
  
  // 충돌 포인트 시각화 업데이트
  private updateCollisionPoints(): void {
    if (!this.collisionGraphics || !this.isDebugMode) return;
    
    this.collisionGraphics.clear();
    
    // 각 충돌 포인트 표시
    this.collisionPoints.forEach(point => {
      // 시간 경과에 따라 투명도 조절 (오래된 포인트일수록 투명해짐)
      const age = this.scene.time.now - point.time;
      const alpha = 1 - (age / this.COLLISION_POINT_LIFETIME);
      
      this.collisionGraphics.fillStyle(0xffff00, alpha);
      this.collisionGraphics.fillCircle(point.x, point.y, 4);
    });
  }
  
  // 디버그 모드 상태 확인
  public isDebugEnabled(): boolean {
    return this.isDebugMode;
  }
} 