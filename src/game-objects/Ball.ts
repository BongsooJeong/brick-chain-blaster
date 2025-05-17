import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class Ball {
  private scene: Phaser.Scene;
  private ball: Phaser.Physics.Arcade.Sprite;
  private glowEffect: Phaser.GameObjects.Sprite | null = null;
  private trailEffects: Phaser.GameObjects.Rectangle[] = [];
  private lastTrailPosition = { x: 0, y: 0 };
  private trailFrequency = 4; // 몇 프레임마다 트레일을 추가할지 설정 (값이 클수록 덜 빈번함)
  private frameCount = 0;
  
  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.scene = scene;
    
    // 공 스프라이트 생성
    this.ball = scene.physics.add.sprite(x, y, 'ball');
    
    // 글로우 효과 추가
    this.setupGlowEffect();
    
    // 공의 물리 속성 설정
    this.ball.setCollideWorldBounds(true);
    
    // 공이 가장자리에서 벗어날 경우 이벤트 설정
    if (this.ball.body) {
      // 반발 계수 설정
      this.ball.body.bounce.set(PHYSICS_CONSTANTS.BALL.RESTITUTION);
      
      // 중력 영향 없음
      this.ball.body.gravity.set(0, 0);
      
      // 공 회전 설정
      this.ball.setAngularVelocity(PHYSICS_CONSTANTS.BALL.ANGULAR_VELOCITY);
    }
    
    // 트레일 위치 초기화
    this.lastTrailPosition = { x, y };
  }
  
  // 글로우 효과 설정
  private setupGlowEffect(): void {
    try {
      // 공 주위에 글로우 효과
      this.glowEffect = this.scene.add.sprite(
        this.ball.x,
        this.ball.y,
        'ball'
      );
      
      // 글로우 스케일 및 알파 설정
      this.glowEffect.setScale(1.5);
      this.glowEffect.setAlpha(0.3);
      this.glowEffect.setBlendMode(Phaser.BlendModes.ADD);
      this.glowEffect.setTint(0x00ffff); // 청록색 글로우
      this.glowEffect.setDepth(0); // 공보다 뒤에 배치
      
      // 글로우 펄싱 애니메이션
      this.scene.tweens.add({
        targets: this.glowEffect,
        scale: { from: 1.3, to: 1.5 },
        alpha: { from: 0.2, to: 0.3 },
        duration: 800,
        ease: 'Sine.easeInOut',
        yoyo: true,
        repeat: -1
      });
    } catch (error) {
      console.log('글로우 효과를 생성하는 중 오류 발생:', error);
      this.glowEffect = null;
    }
  }
  
  // 트레일 효과 추가
  private addTrailEffect(): void {
    // 최대 10개의 트레일 효과 유지
    if (this.trailEffects.length >= 10) {
      // 가장 오래된 트레일 제거
      const oldTrail = this.trailEffects.shift();
      if (oldTrail) {
        oldTrail.destroy();
      }
    }
    
    // 새 트레일 효과 추가
    const trail = this.scene.add.rectangle(
      this.ball.x,
      this.ball.y,
      this.ball.width * 0.8,
      this.ball.height * 0.8,
      0x00ffff,
      0.3
    );
    
    // 블렌드 모드 및 깊이 설정
    trail.setBlendMode(Phaser.BlendModes.ADD);
    trail.setDepth(-1); // 공보다 뒤에 배치
    
    // 트레일 배열에 추가
    this.trailEffects.push(trail);
    
    // 트레일 페이드아웃 애니메이션
    this.scene.tweens.add({
      targets: trail,
      alpha: 0,
      scale: 0.5,
      duration: 300,
      onComplete: () => {
        trail.destroy();
        this.trailEffects = this.trailEffects.filter(t => t !== trail);
      }
    });
  }
  
  // 공 발사 메서드
  public launch(): void {
    this.ball.setVelocity(
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.x,
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.y
    );
  }
  
  // 공의 물리 업데이트 (프레임 레이트 독립적)
  public updatePhysics(delta: number): void {
    if (this.ball.body && this.ball.active) {
      // 현재 속도 확인
      const velocity = this.ball.body.velocity;
      const speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
      
      // 속도가 너무 느리면 조정
      if (speed < PHYSICS_CONSTANTS.BALL.MIN_VELOCITY) {
        const factor = PHYSICS_CONSTANTS.BALL.MIN_VELOCITY / speed;
        this.ball.body.velocity.x *= factor;
        this.ball.body.velocity.y *= factor;
      }
      // 속도가 너무 빠르면 제한
      else if (speed > PHYSICS_CONSTANTS.BALL.MAX_VELOCITY) {
        const factor = PHYSICS_CONSTANTS.BALL.MAX_VELOCITY / speed;
        this.ball.body.velocity.x *= factor;
        this.ball.body.velocity.y *= factor;
      }
    }
    
    // 글로우 효과 업데이트
    if (this.glowEffect) {
      this.glowEffect.x = this.ball.x;
      this.glowEffect.y = this.ball.y;
    }
    
    // N 프레임마다 트레일 생성 (성능을 위해)
    this.frameCount = (this.frameCount + 1) % this.trailFrequency;
    
    if (this.frameCount === 0 && 
        this.ball.active && 
        (Math.abs(this.lastTrailPosition.x - this.ball.x) > 5 || 
         Math.abs(this.lastTrailPosition.y - this.ball.y) > 5)) {
      
      this.addTrailEffect();
      this.lastTrailPosition = { x: this.ball.x, y: this.ball.y };
    }
  }
  
  // 볼 위치 재설정
  public reset(x: number, y: number): void {
    this.ball.setPosition(x, y);
    this.ball.setVelocity(0, 0);
    this.ball.setAngularVelocity(0);
    this.ball.setActive(true);
    this.ball.setVisible(true);
    
    // 트레일 효과 모두 제거
    this.trailEffects.forEach(trail => {
      trail.destroy();
    });
    this.trailEffects = [];
    
    // 글로우 효과 위치 재설정
    if (this.glowEffect) {
      this.glowEffect.x = x;
      this.glowEffect.y = y;
      this.glowEffect.setVisible(true);
    }
  }
  
  // 공이 패들에 닿았을 때 속도 증가 및 방향 조정
  public hitPaddle(paddle: Phaser.Physics.Arcade.Sprite): void {
    // 패들의 영역을 5등분하여 각 구역에 따라 다른 반사각 적용
    const diff = this.ball.x - paddle.x;
    const paddleHalfWidth = paddle.width / 2;
    
    // 패들의 어느 부분에 부딪혔는지에 따라 각도 계산
    // -1 ~ 1 사이의 값으로 정규화 (왼쪽 끝: -1, 중앙: 0, 오른쪽 끝: 1)
    const factor = diff / paddleHalfWidth;
    
    // 속도 유지하면서 방향만 조정
    if (this.ball.body) {
      // 현재 속도 계산
      const currentSpeed = Math.sqrt(
        this.ball.body.velocity.x ** 2 + this.ball.body.velocity.y ** 2
      );
      
      // 반사각 계산 (factor에 따라 -60도 ~ +60도)
      const angle = factor * Math.PI / 3; // 최대 60도 (π/3)
      
      // 공 속도 계산 (위쪽 방향으로)
      const velocityX = Math.sin(angle) * currentSpeed;
      const velocityY = -Math.cos(angle) * currentSpeed;
      
      // 공 속도 설정
      this.ball.body.velocity.x = velocityX;
      this.ball.body.velocity.y = velocityY;
      
      // 속도 살짝 증가 (게임 진행에 따라 난이도 상승)
      this.ball.body.velocity.x *= PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR;
      this.ball.body.velocity.y *= PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR;
      
      // 히트 이펙트 생성
      this.createHitEffect();
    }
  }
  
  // 충돌 이펙트 생성
  private createHitEffect(): void {
    // 충돌 지점에 원형 파티클 이펙트 생성
    const hitEffect = this.scene.add.circle(
      this.ball.x,
      this.ball.y,
      this.ball.width / 2,
      0xffffff,
      0.8
    );
    
    hitEffect.setBlendMode(Phaser.BlendModes.ADD);
    
    // 충돌 이펙트 애니메이션
    this.scene.tweens.add({
      targets: hitEffect,
      alpha: 0,
      scale: 2.5,
      duration: 400,
      ease: 'Cubic.easeOut',
      onComplete: () => {
        hitEffect.destroy();
      }
    });
  }
  
  // 공 스프라이트 가져오기
  public getSprite(): Phaser.Physics.Arcade.Sprite {
    return this.ball;
  }
  
  // 공의 활성 상태 설정
  public setActive(active: boolean): void {
    this.ball.setActive(active);
    this.ball.setVisible(active);
  }
} 