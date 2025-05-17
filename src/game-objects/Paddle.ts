import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class Paddle {
  private scene: Phaser.Scene;
  private paddle: Phaser.Physics.Arcade.Sprite;
  private glowEffect: Phaser.GameObjects.Rectangle;
  private trailEffects: Phaser.GameObjects.Rectangle[] = [];
  
  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.scene = scene;
    
    // 패들 생성
    this.paddle = scene.physics.add.sprite(x, y, 'paddle');
    this.paddle.setImmovable(true);
    this.paddle.setCollideWorldBounds(true);
    
    // 패들 글로우 효과
    this.glowEffect = this.createGlowEffect();
    
    // 패들 리사이즈 애니메이션
    this.setupPaddleAnimations();
  }
  
  // 글로우 효과 생성
  private createGlowEffect(): Phaser.GameObjects.Rectangle {
    const glow = this.scene.add.rectangle(
      this.paddle.x,
      this.paddle.y,
      this.paddle.width + 10,
      this.paddle.height + 6,
      0x00ffff, // 청록색 글로우
      0.3
    );
    
    glow.setBlendMode(Phaser.BlendModes.ADD);
    glow.setDepth(0); // 패들 뒤에 그려지도록
    
    // 글로우 펄싱 애니메이션
    this.scene.tweens.add({
      targets: glow,
      alpha: { from: 0.2, to: 0.4 },
      duration: 1000,
      ease: 'Sine.easeInOut',
      yoyo: true,
      repeat: -1
    });
    
    return glow;
  }
  
  // 트레일 효과 추가
  private addTrailEffect(): void {
    // 최대 5개의 트레일 효과 유지
    if (this.trailEffects.length >= 5) {
      // 가장 오래된 트레일 제거
      const oldTrail = this.trailEffects.shift();
      if (oldTrail) {
        // 투명도 애니메이션 후 제거
        this.scene.tweens.add({
          targets: oldTrail,
          alpha: 0,
          duration: 200,
          onComplete: () => {
            oldTrail.destroy();
          }
        });
      }
    }
    
    // 새 트레일 효과 추가
    const trail = this.scene.add.rectangle(
      this.paddle.x,
      this.paddle.y,
      this.paddle.width * 0.9,
      this.paddle.height * 0.9,
      0x00ffff,
      0.2
    );
    
    trail.setBlendMode(Phaser.BlendModes.ADD);
    trail.setDepth(-1);
    
    // 트레일 배열에 추가
    this.trailEffects.push(trail);
    
    // 트레일 페이드아웃 애니메이션
    this.scene.tweens.add({
      targets: trail,
      alpha: 0,
      scale: 0.8,
      duration: 300,
      onComplete: () => {
        trail.destroy();
        this.trailEffects = this.trailEffects.filter(t => t !== trail);
      }
    });
  }
  
  // 패들 애니메이션 설정
  private setupPaddleAnimations(): void {
    // 패들 눌려짐 애니메이션 - 공이 패들에 닿을 때 사용
    this.scene.tweens.add({
      targets: this.paddle,
      scaleY: { from: 1, to: 0.9 },
      duration: 100,
      ease: 'Bounce.easeInOut',
      yoyo: true,
      repeat: 0,
      paused: true
    });
  }
  
  // 패들 위치 업데이트
  public moveTo(x: number): void {
    const prevX = this.paddle.x; // 이전 위치 저장
    const halfWidth = this.paddle.width / 2;
    const gameWidth = this.scene.cameras.main.width;
    
    // 패들이 화면 경계를 벗어나지 않도록 제한
    this.paddle.x = Phaser.Math.Clamp(
      x,
      halfWidth,
      gameWidth - halfWidth
    );
    
    // 글로우 효과 위치 업데이트
    this.glowEffect.x = this.paddle.x;
    this.glowEffect.y = this.paddle.y;
    
    // 패들이 충분히 움직였을 때만 트레일 추가
    const isMovingFast = Math.abs(prevX - this.paddle.x) > 3;
    if (isMovingFast) {
      this.addTrailEffect();
    }
  }
  
  // 패들 x 위치 가져오기
  public getX(): number {
    return this.paddle.x;
  }
  
  // 패들 스프라이트 가져오기
  public getSprite(): Phaser.Physics.Arcade.Sprite {
    return this.paddle;
  }
  
  // 충돌 애니메이션 재생
  public playHitAnimation(): void {
    // 찌그러짐 애니메이션 재생
    const paddleTweens = this.scene.tweens.getTweens().filter(
      t => t.targets.includes(this.paddle)
    );
    
    if (paddleTweens.length > 0) {
      paddleTweens[0].restart();
    }
    
    // 글로우 플래시 효과
    this.scene.tweens.add({
      targets: this.glowEffect,
      alpha: { from: 0.8, to: 0.3 },
      duration: 300,
      ease: 'Cubic.easeOut'
    });
  }
} 