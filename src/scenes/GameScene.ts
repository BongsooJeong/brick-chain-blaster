import Phaser from 'phaser';
import { PHYSICS_CONSTANTS } from '../constants/PhysicsConstants';
import { Ball } from '../game-objects/Ball';
import { Paddle } from '../game-objects/Paddle';
import { BrickManager } from '../game-objects/Brick';
import { Walls } from '../game-objects/Walls';
import { DebugManager } from '../utils/DebugUtils';

export class GameScene extends Phaser.Scene {
  // 게임 객체
  private paddle!: Paddle;
  private ball!: Ball;
  private brickManager!: BrickManager;
  private walls!: Walls;
  
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
    // 배경 이미지 추가
    this.add.image(0, 0, 'background')
      .setOrigin(0)
      .setDisplaySize(this.cameras.main.width, this.cameras.main.height);
    
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
    // 벽과 공 사이의 충돌
    const walls = this.walls.getWalls();
    const wallNames = this.walls.getWallNames();
    
    walls.forEach((wall, index) => {
      this.physics.add.collider(
        this.ball.getSprite(), 
        wall, 
        () => {
          // 충돌 사운드 재생 (벽에 따라 다른 효과)
          const detune = index === 0 ? -200 : 0; // 상단 벽은 다른 음조
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
          
          // 디버그 모드일 때 충돌 정보 표시
          if (this.debugManager.isDebugEnabled()) {
            console.log(`벽 충돌: ${wallNames[index]}`);
          }
        }
      );
    });
    
    // 공과 패들 사이의 충돌
    this.physics.add.collider(
      this.ball.getSprite(),
      this.paddle.getSprite(),
      () => {
        this.sound.play('bounce');
        this.ball.hitPaddle(this.paddle.getSprite());
        
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
      },
      undefined,
      this
    );
    
    // 공과 벽돌 사이의 충돌
    this.physics.add.collider(
      this.ball.getSprite(),
      this.brickManager.getGroup(),
      (ball, brick) => {
        // 충돌 위치 및 속도 기록 (디버그 시각화용)
        const ballSprite = ball as Phaser.Physics.Arcade.Sprite;
        if (ballSprite.body) {
          this.debugManager.recordCollision(
            ballSprite.x,
            ballSprite.y,
            ballSprite.body.velocity.x,
            ballSprite.body.velocity.y
          );
        }
        
        // 공과 벽돌 충돌 처리
        this.ball.hitBrick(brick as Phaser.Physics.Arcade.Sprite);
        
        // 벽돌 제거
        (brick as Phaser.Physics.Arcade.Sprite).destroy();
        this.sound.play('break');
        
        // 점수 추가
        this.score += 10;
        this.scoreText.setText(`점수: ${this.score}`);
        
        // 모든 벽돌이 제거되면 게임 클리어
        if (this.brickManager.getActiveCount() === 0) {
          this.gameWin();
        }
      },
      undefined,
      this
    );
  }

  update(time: number, delta: number): void {
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

  private gameWin(): void {
    this.ball.getSprite().setVelocity(0, 0);
    this.gameStarted = false;
    
    this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2,
      '축하합니다!\n클리어하셨습니다!',
      {
        fontFamily: 'Arial',
        fontSize: '48px',
        color: '#00ff00',
        stroke: '#000',
        strokeThickness: 6,
        align: 'center'
      }
    ).setOrigin(0.5);
    
    this.restartButton.setVisible(true);
  }
} 