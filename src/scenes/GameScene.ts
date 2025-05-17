import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';
import { Ball } from '../game-objects/Ball';
import { Paddle } from '../game-objects/Paddle';
import { BrickManager } from '../game-objects/Brick';
import { Walls } from '../game-objects/Walls';
import { DebugManager } from '../utils/DebugUtils';
import { BackgroundManager } from '../utils/BackgroundManager';

export class GameScene extends Phaser.Scene {
  // 게임 객체
  private paddle!: Paddle;
  private ball!: Ball;
  private brickManager!: BrickManager;
  private walls!: Walls;
  private backgroundManager!: BackgroundManager;
  
  // UI 요소
  private scoreText!: Phaser.GameObjects.Text;
  private livesText!: Phaser.GameObjects.Text;
  private gameOverText!: Phaser.GameObjects.Text;
  private restartButton!: Phaser.GameObjects.Text;
  
  // 디버그 관련
  private debugManager!: DebugManager;
  
  // 게임 상태 변수
  private score = 0;
  private lives = 3;
  private gameStarted = false;

  constructor() {
    super('GameScene');
  }

  create(): void {
    // 배경 매니저 초기화
    this.backgroundManager = new BackgroundManager(this);
    
    // 게임 객체 초기화
    this.initGameObjects();
    
    // 점수 텍스트
    this.scoreText = this.add.text(16, 16, '점수: 0', {
      fontFamily: 'Arial',
      fontSize: '24px',
      color: '#ffffff'
    });

    // 생명 텍스트
    this.livesText = this.add.text(
      this.cameras.main.width - 16, 
      16, 
      `생명: ${this.lives}`, 
      {
        fontFamily: 'Arial',
        fontSize: '24px',
        color: '#ffffff'
      }
    ).setOrigin(1, 0);
    
    // 충돌 설정
    this.setupCollisions();
    
    // 게임 오버 텍스트 (비활성화 상태로 시작)
    this.gameOverText = this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2,
      'GAME OVER',
      {
        fontFamily: 'Arial',
        fontSize: '64px',
        color: '#ff0000',
        stroke: '#000',
        strokeThickness: 6
      }
    ).setOrigin(0.5);
    this.gameOverText.setVisible(false);

    // 다시 시작 버튼 (비활성화 상태로 시작)
    this.restartButton = this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2 + 80,
      '다시 시작',
      {
        fontFamily: 'Arial',
        fontSize: '32px',
        color: '#ffffff',
        backgroundColor: '#222222',
        padding: { x: 20, y: 10 }
      }
    ).setOrigin(0.5).setInteractive({ useHandCursor: true });
    this.restartButton.setVisible(false);

    this.restartButton.on('pointerdown', () => {
      this.scene.restart();
    });
    
    // 입력 처리 설정
    this.setupInputHandlers();
  }
  
  // 게임 객체 초기화
  private initGameObjects(): void {
    // 벽 생성
    this.walls = new Walls(this);
    
    // 물리 디버그 설정 초기화
    // 시작 시에 디버그 그래픽을 명시적으로 설정
    if (!this.physics.world.debugGraphic) {
      this.physics.world.createDebugGraphic();
    }
    
    // 디버그 설정
    this.debugManager = new DebugManager(this);
    
    // 패들 생성
    this.paddle = new Paddle(
      this,
      this.cameras.main.width / 2,
      this.cameras.main.height - 50
    );
    
    // 공 생성
    this.ball = new Ball(
      this,
      this.cameras.main.width / 2,
      this.cameras.main.height - 100
    );
    
    // 세계 경계 충돌 이벤트 설정
    this.physics.world.on('worldbounds', this.onWorldBounds, this);
    
    // 벽돌 매니저 생성
    this.brickManager = new BrickManager(this);
    this.brickManager.createBricks();
  }
  
  // 입력 처리 설정
  private setupInputHandlers(): void {
    // 마우스 이동
    this.input.on('pointermove', (pointer: Phaser.Input.Pointer) => {
      this.paddle.moveTo(pointer.x);
      
      if (!this.gameStarted) {
        this.ball.reset(this.paddle.getX(), this.cameras.main.height - 100);
      }
    });
    
    // 마우스 클릭
    this.input.on('pointerdown', () => {
      if (!this.gameStarted) {
        this.gameStarted = true;
        this.ball.launch();
      }
    });
    
    // 디버그 모드 토글 키 설정
    this.input.keyboard?.addKey('D').on('down', () => {
      this.debugManager.toggleDebugMode();
    });
    
    // 스페이스바
    this.input.keyboard?.addKey('SPACE').on('down', () => {
      if (!this.gameStarted) {
        this.gameStarted = true;
        this.ball.launch();
      }
    });
  }
  
  // 충돌 설정
  private setupCollisions(): void {
    // 공과 패들 간 충돌
    this.physics.add.collider(
      this.ball.getSprite(),
      this.paddle.getSprite(),
      this.onBallHitPaddle as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
      undefined,
      this
    );
    
    // 공과 벽돌 간 충돌
    this.physics.add.collider(
      this.ball.getSprite(),
      this.brickManager.getGroup(),
      this.onBallHitBrick as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
      undefined,
      this
    );
    
    // 공과 월드 경계 충돌 이벤트
    const ballSprite = this.ball.getSprite();
    ballSprite.setCollideWorldBounds(true, undefined, undefined, true);
    
    // 벽 충돌 설정 (충돌 및 겹침 설정)
    this.walls.getWalls().forEach(wall => {
      this.physics.add.collider(
        this.ball.getSprite(),
        wall,
        this.onBallHitWall as Phaser.Types.Physics.Arcade.ArcadePhysicsCallback,
        undefined,
        this
      );
    });
  }

  // 공과 패들 충돌 처리
  private onBallHitPaddle(
    _ball: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile,
    _paddle: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile
  ): void {
    // 공의 패들 충돌 물리 처리
    this.ball.hitPaddle(this.paddle.getSprite());
    
    // 패들 히트 애니메이션 재생
    this.paddle.playHitAnimation();
    
    // 패들 히트 사운드 재생
    this.sound.play('paddleHit');
    
    // 히트 시 점수 증가
    this.score += 5;
    this.scoreText.setText(`점수: ${this.score}`);
  }
  
  // 공과 벽돌 충돌 처리
  private onBallHitBrick(
    _ball: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile,
    _brick: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile
  ): void {
    // 벽돌을 비활성화하고 화면에서 숨김
    const brick = _brick as Phaser.Physics.Arcade.Sprite;
    brick.disableBody(true, true);
    
    // 충돌 히트 이펙트 생성
    this.createBrickHitEffect(brick.x, brick.y, brick.width, brick.height);
    
    // 점수 증가
    this.score += 10;
    this.scoreText.setText(`점수: ${this.score}`);
    
    // 벽돌 파괴 사운드 재생
    this.sound.play('brickDestroy');
    
    // 남은 벽돌 수 체크
    const activeCount = this.brickManager.getActiveCount();
    if (activeCount === 0) {
      this.gameWin();
    }
  }

  // 공과 벽 충돌 처리
  private onBallHitWall(
    _ball: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile,
    _wall: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Tilemaps.Tile
  ): void {
    // 벽 충돌 시 사운드 재생
    this.sound.play('bounce', { volume: 0.3 });
  }
  
  // 게임 승리 처리
  private gameWin(): void {
    this.gameStarted = false;
    
    // 승리 메시지 표시
    const winText = this.add.text(
      this.cameras.main.width / 2, 
      this.cameras.main.height / 2 - 50,
      '레벨 클리어!',
      {
        fontSize: '32px',
        fontFamily: 'Arial',
        color: '#ffff00',
        stroke: '#000000',
        strokeThickness: 4
      }
    ).setOrigin(0.5);
    
    // 성공 효과 생성
    this.createWinEffect();
    
    // 공 재설정
    this.ball.reset(
      this.paddle.getX(),
      this.cameras.main.height - 80
    );
    
    // 다음 레벨/재시작 버튼
    this.restartButton.setText('다음 레벨');
    this.restartButton.setVisible(true);
  }
  
  // 승리 효과 생성
  private createWinEffect(): void {
    // 화면 전체에 빛나는 효과
    const shine = this.add.rectangle(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2,
      this.cameras.main.width,
      this.cameras.main.height,
      0xffff00,
      0.2
    );
    
    shine.setBlendMode(Phaser.BlendModes.ADD);
    
    // 반짝이는 애니메이션
    this.tweens.add({
      targets: shine,
      alpha: 0,
      duration: 1000,
      ease: 'Sine.easeOut'
    });
    
    // 축하 파티클 효과 (상단에서 떨어지는)
    if (this.textures.exists('particle')) {
      const confetti = this.add.particles(0, 0, 'particle', {
        x: { min: 0, max: this.cameras.main.width },
        y: -10,
        speedY: { min: 100, max: 200 },
        speedX: { min: -20, max: 20 },
        scale: { start: 0.5, end: 0.1 },
        lifespan: 2000,
        tint: [0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0xff00ff],
        frequency: 50,
        quantity: 5,
        blendMode: Phaser.BlendModes.ADD
      });
      
      // 3초 후에 파티클 효과 제거
      this.time.delayedCall(3000, () => {
        if (confetti) confetti.destroy();
      });
    }
  }

  update(time: number, delta: number): void {
    // 배경 업데이트
    this.backgroundManager.update(time, delta);
    
    // 공이 하단 경계 아래로 떨어졌는지 확인 (공이 유효하고 활성화된 경우만)
    if (this.ball.getSprite().active && this.ball.getSprite().y > this.cameras.main.height) {
      this.handleBallFall();
    }
    
    // 프레임 레이트 독립적인 물리 업데이트
    if (this.gameStarted && this.ball.getSprite().active) {
      this.ball.updatePhysics(delta);
    }
    
    // 디버그 정보 업데이트 (time과 delta 전달)
    this.debugManager.updateDebugInfo(this.ball.getSprite(), time, delta);
  }
  
  private onWorldBounds(body: Phaser.Physics.Arcade.Body, up: boolean, down: boolean, left: boolean, right: boolean): void {
    // 공이 세계 경계에 부딪혔을 때 처리
    if (body.gameObject !== this.ball.getSprite()) return;
    
    // 위, 왼쪽, 오른쪽 경계에 부딪힌 경우 사운드 재생
    if (up || left || right) {
      // 부딪힌 방향에 따라 다른 사운드 효과 적용
      let detune = 0;
      if (up) detune = -200;
      this.sound.play('bounce', { volume: 0.5, detune });
      
      // 충돌 위치 및 속도 기록 (디버그 시각화용)
      const ballSprite = this.ball.getSprite();
      if (ballSprite.body) {
        this.debugManager.recordCollision(
          ballSprite.x,
          ballSprite.y,
          ballSprite.body.velocity.x,
          ballSprite.body.velocity.y
        );
      }
    }
    
    // 디버그 모드에서 추가 정보 표시
    if (this.debugManager.isDebugEnabled()) {
      let direction = 'unknown';
      if (up) direction = '상';
      if (down) direction = '하';
      if (left) direction = '좌';
      if (right) direction = '우';
      
      console.log(`세계 경계 충돌: ${direction}`);
    }
  }

  private handleBallFall(): void {
    // 하단 경계 통과 효과음 재생 (fall 사운드가 존재하는 경우)
    if (this.sound.get('fall')) {
      this.sound.play('fall', { volume: 0.7 });
    } else {
      // fall 사운드가 없으면 gameover 사운드를 대신 사용
      this.sound.play('gameover', { volume: 0.4, detune: 400 });
    }
    
    // 생명 감소
    this.lives--;
    this.livesText.setText(`생명: ${this.lives}`);
    
    // 화면에 경고 표시 (잠시 깜박임)
    const flashOverlay = this.add.rectangle(
      0, 0, this.cameras.main.width, this.cameras.main.height, 0xff0000, 0.3
    ).setOrigin(0, 0);
    
    this.tweens.add({
      targets: flashOverlay,
      alpha: 0,
      duration: 300,
      onComplete: () => {
        flashOverlay.destroy();
      }
    });

    if (this.lives === 0) {
      this.gameOver();
    } else {
      this.resetBall();
    }
  }

  private resetBall(): void {
    this.ball.reset(this.paddle.getX(), this.cameras.main.height - 100);
    this.gameStarted = false;
  }

  private gameOver(): void {
    this.ball.getSprite().setVelocity(0, 0);
    this.gameStarted = false;
    this.sound.play('gameover');
    
    this.gameOverText.setVisible(true);
    this.restartButton.setVisible(true);
  }

  // 벽돌 파괴 이펙트 생성
  private createBrickHitEffect(x: number, y: number, width: number, height: number): void {
    // 벽돌 위치에 파티클 생성
    const particles = this.add.particles(x, y, 'particle', {
      speed: { min: 50, max: 150 },
      angle: { min: 0, max: 360 },
      scale: { start: 0.6, end: 0.1 },
      lifespan: { min: 600, max: 800 },
      blendMode: Phaser.BlendModes.ADD,
      tint: [0xffff00, 0xff8800, 0xff4400],
      quantity: 15,
      gravityY: 300
    });
    
    // 파티클 이미지가 없는 경우에 대비한 텍스처 생성
    if (!this.textures.exists('particle')) {
      this.createParticleTexture();
    }
    
    // 잠시 후 파티클 시스템 제거
    this.time.delayedCall(800, () => {
      if (particles) particles.destroy();
    });
    
    // 추가 시각 효과: 벽돌 위치에 원형 펄스 이펙트
    const pulse = this.add.circle(x, y, width / 2, 0xffffff, 0.7);
    pulse.setBlendMode(Phaser.BlendModes.ADD);
    
    // 펄스 애니메이션
    this.tweens.add({
      targets: pulse,
      alpha: 0,
      scale: 2,
      duration: 300,
      ease: 'Cubic.easeOut',
      onComplete: () => {
        pulse.destroy();
      }
    });
  }
  
  // 파티클 텍스처 생성 (재사용 가능하도록 별도 메서드로)
  private createParticleTexture(): void {
    const graphics = this.make.graphics({ x: 0, y: 0 });
    graphics.fillStyle(0xffffff, 1);
    graphics.fillCircle(8, 8, 8);
    graphics.generateTexture('particle', 16, 16);
    graphics.destroy();
  }
} 