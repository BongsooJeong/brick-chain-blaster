import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';

export class Ball {
  private scene: Phaser.Scene;
  private ball: Phaser.Physics.Arcade.Sprite;
  
  constructor(scene: Phaser.Scene, x: number, y: number) {
    this.scene = scene;
    
    // 공 스프라이트 생성
    this.ball = scene.physics.add.sprite(x, y, 'ball');
    
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
  }
  
  // 공 발사 메서드
  public launch(): void {
    this.ball.setVelocity(
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.x,
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.y
    );
  }
  
  // 공 위치 재설정
  public reset(x: number, y: number): void {
    this.ball.setPosition(x, y);
    this.ball.setVelocity(0, 0);
  }
  
  // 공 물리 업데이트 (프레임 레이트 독립적)
  public updatePhysics(delta: number): void {
    if (!this.ball.body) return;
    
    // 현재 속도 계산
    const velocityX = this.ball.body.velocity.x;
    const velocityY = this.ball.body.velocity.y;
    const currentSpeed = Math.sqrt(velocityX * velocityX + velocityY * velocityY);
    
    // 최소 속도 보장
    if (currentSpeed < PHYSICS_CONSTANTS.BALL.MIN_VELOCITY && currentSpeed > 0) {
      const factor = PHYSICS_CONSTANTS.BALL.MIN_VELOCITY / currentSpeed;
      this.ball.body.velocity.x *= factor;
      this.ball.body.velocity.y *= factor;
    }
    
    // 프레임 레이트에 영향받지 않는 이동 보정 (필요한 경우)
    // delta는 ms 단위이므로 초 단위로 변환 (delta/1000)
    const timeCorrection = delta / (1000 / 60); // 60fps 기준 보정
    
    // 이 예시에서는 Phaser의 내장 물리 엔진이 이미 delta를 처리하기 때문에
    // 추가 보정은 필요 없지만, 사용자 정의 물리 로직이 필요한 경우 여기에 구현
  }
  
  // 패들과 충돌 처리
  public hitPaddle(paddle: Phaser.Physics.Arcade.Sprite): void {
    // 패들의 어느 부분에 맞았는지에 따라 공의 x 속도 조정
    const diff = this.ball.x - paddle.x;
    
    // 패들 충돌 물리 로직 개선
    // 1. 패들 중앙에서 떨어진 거리에 비례하여 반사 각도 결정
    const paddleWidth = paddle.width;
    const normalizedDiff = diff / (paddleWidth / 2); // -1.0 ~ 1.0 범위로 정규화
    
    // 2. 기본 Y 속도 (항상 위쪽으로)
    const upwardVelocity = -300;
    
    // 3. 패들 타격 위치에 따른 X 속도 계산 (좌우 각도 조절)
    const horizontalVelocity = normalizedDiff * 300; // 최대 좌우 속도 ±300
    
    // 4. 최종 속도 설정 (이전 속도와 새로운 속도 병합)
    this.ball.setVelocity(horizontalVelocity, upwardVelocity);
    
    // 5. 패들 히트 시 속도 미세 증가 (난이도 상승)
    const currentVelocity = this.ball.body?.velocity;
    if (currentVelocity) {
      const speed = Math.sqrt(currentVelocity.x * currentVelocity.x + currentVelocity.y * currentVelocity.y);
      const newSpeed = Math.min(speed * PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR, PHYSICS_CONSTANTS.BALL.MAX_VELOCITY);
      
      if (newSpeed > speed) {
        const factor = newSpeed / speed;
        this.ball.setVelocity(currentVelocity.x * factor, currentVelocity.y * factor);
      }
    }
  }
  
  // 벽돌과 충돌 처리
  public hitBrick(brick: Phaser.Physics.Arcade.Sprite): void {
    // ball.body가 null이 아닌지 확인
    if (!this.ball.body) return;
    
    // 공의 현재 속도를 벽돌 제거 전에 저장
    const velocityX = this.ball.body.velocity.x;
    const velocityY = this.ball.body.velocity.y;
    
    // 충돌 방향 분석을 위한 계산
    const brickCenter = brick.getCenter();
    const ballCenter = this.ball.getCenter();
    
    // 벽돌 중심과 공 중심의 위치 차이 계산
    const dx = ballCenter.x - brickCenter.x;
    const dy = ballCenter.y - brickCenter.y;
    
    // 충돌 위치 분석 (공이 벽돌의 어느 면에 부딪혔는지 결정)
    // 이 값이 클수록 수평면 충돌, 작을수록 수직면 충돌
    const absDX = Math.abs(dx);
    const absDY = Math.abs(dy);
    
    // 충돌 후 공의 속도 계산
    let newVelocityX = velocityX;
    let newVelocityY = velocityY;
    
    // 좌우측면 충돌인 경우 (수평 방향 충돌이 더 강함)
    if (absDX >= absDY) {
      // X축 방향으로 튕김
      newVelocityX = -velocityX * PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR; // 약간 빨라지게
      
      // 공이 너무 수직으로 움직이면 각도 조정
      if (Math.abs(newVelocityY) < 60) {
        newVelocityY = newVelocityY < 0 ? -60 : 60;
      }
    } 
    // 상하측면 충돌인 경우 (수직 방향 충돌이 더 강함)
    else {
      // Y축 방향으로 튕김
      newVelocityY = -velocityY * PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR; // 약간 빨라지게
      
      // 공이 너무 수평으로 움직이면 각도 조정
      if (Math.abs(newVelocityX) < 60) {
        newVelocityX = newVelocityX < 0 ? -60 : 60;
      }
    }
    
    // 최소 속도 보장
    const minSpeed = PHYSICS_CONSTANTS.BALL.MIN_VELOCITY;
    const currentSpeed = Math.sqrt(newVelocityX * newVelocityX + newVelocityY * newVelocityY);
    if (currentSpeed < minSpeed) {
      const angle = Math.atan2(newVelocityY, newVelocityX);
      newVelocityX = Math.cos(angle) * minSpeed;
      newVelocityY = Math.sin(angle) * minSpeed;
    }
    
    // 최대 속도 제한
    const maxSpeed = PHYSICS_CONSTANTS.BALL.MAX_VELOCITY;
    if (currentSpeed > maxSpeed) {
      const ratio = maxSpeed / currentSpeed;
      newVelocityX *= ratio;
      newVelocityY *= ratio;
    }
    
    // 공 속도 설정
    this.ball.setVelocity(newVelocityX, newVelocityY);
  }
  
  // Getter: 공 스프라이트 객체 반환
  public getSprite(): Phaser.Physics.Arcade.Sprite {
    return this.ball;
  }
  
  // 공의 활성 상태 설정
  public setActive(active: boolean): void {
    this.ball.setActive(active);
    this.ball.setVisible(active);
  }
} 