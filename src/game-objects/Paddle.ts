import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class Paddle {
  private scene: Phaser.Scene;
  private paddle: Phaser.Physics.Arcade.Sprite;
  
  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.scene = scene;
    
    // 패들 생성
    this.paddle = scene.physics.add.sprite(x, y, 'paddle');
    this.paddle.setImmovable(true);
    this.paddle.setCollideWorldBounds(true);
  }
  
  // 패들 위치 업데이트
  public moveTo(x: number): void {
    const halfWidth = this.paddle.width / 2;
    const gameWidth = this.scene.cameras.main.width;
    
    // 패들이 화면 경계를 벗어나지 않도록 제한
    this.paddle.x = Phaser.Math.Clamp(
      x,
      halfWidth,
      gameWidth - halfWidth
    );
  }
  
  // 패들 x 위치 가져오기
  public getX(): number {
    return this.paddle.x;
  }
  
  // 패들 스프라이트 가져오기
  public getSprite(): Phaser.Physics.Arcade.Sprite {
    return this.paddle;
  }
} 