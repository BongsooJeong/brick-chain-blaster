import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class DebugManager {
  private scene: Phaser.Scene;
  private debugText: Phaser.GameObjects.Text;
  private fpsCounter: Phaser.GameObjects.Text;
  private isDebugMode: boolean = false;
  
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
  }
  
  // 디버그 모드 토글
  public toggleDebugMode(): void {
    this.isDebugMode = !this.isDebugMode;
    
    // 물리 디버그 토글
    this.scene.physics.world.drawDebug = this.isDebugMode;
    this.scene.physics.world.debugGraphic.clear();
    
    // 디버그 UI 요소 가시성 토글
    this.debugText.setVisible(this.isDebugMode);
    this.fpsCounter.setVisible(this.isDebugMode);
    
    console.log(`디버그 모드: ${this.isDebugMode ? '켜짐' : '꺼짐'}`);
  }
  
  // 디버그 텍스트 업데이트
  public updateDebugInfo(ball: Phaser.Physics.Arcade.Sprite): void {
    if (!this.isDebugMode) return;
    
    // FPS 업데이트
    this.fpsCounter.setText(`FPS: ${Math.round(this.scene.game.loop.actualFps)}`);
    
    // 공 정보 업데이트
    if (ball.body) {
      const velocity = ball.body.velocity;
      const speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
      
      this.debugText.setText(
        `공 속도: X=${Math.round(velocity.x)}, Y=${Math.round(velocity.y)}\n` +
        `공 위치: X=${Math.round(ball.x)}, Y=${Math.round(ball.y)}\n` +
        `속력: ${Math.round(speed)}, 최대: ${PHYSICS_CONSTANTS.BALL.MAX_VELOCITY}`
      );
    }
  }
  
  // 디버그 모드 상태 확인
  public isDebugEnabled(): boolean {
    return this.isDebugMode;
  }
} 