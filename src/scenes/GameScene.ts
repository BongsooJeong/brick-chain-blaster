import Phaser from 'phaser';

export class GameScene extends Phaser.Scene {
  private paddle!: Phaser.Physics.Arcade.Sprite;
  private ball!: Phaser.Physics.Arcade.Sprite;
  private bricks!: Phaser.Physics.Arcade.Group;
  private scoreText!: Phaser.GameObjects.Text;
  private livesText!: Phaser.GameObjects.Text;
  private gameOverText!: Phaser.GameObjects.Text;
  private restartButton!: Phaser.GameObjects.Text;
  
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

    // 패들 생성
    this.paddle = this.physics.add.sprite(
      this.cameras.main.width / 2,
      this.cameras.main.height - 50,
      'paddle'
    );
    this.paddle.setImmovable(true);
    this.paddle.setCollideWorldBounds(true);

    // 공 생성
    this.ball = this.physics.add.sprite(
      this.cameras.main.width / 2,
      this.cameras.main.height - 100,
      'ball'
    );
    this.ball.setCollideWorldBounds(true);
    this.ball.setBounce(1);
    
    // 추가 공 속성 설정 (선택적)
    if (this.ball.body) {
      // 공의 질량을 조절하여 더 예측 가능한 움직임
      this.ball.body.bounce.set(1);
      // 중력 영향 없음
      this.ball.body.gravity.set(0, 0);
    }

    // 벽돌 그룹 생성
    this.bricks = this.physics.add.group();
    this.createBricks();

    // 충돌 이벤트
    this.physics.add.collider(
      this.ball,
      this.paddle,
      (ball, paddle) => {
        this.hitPaddle(ball as Phaser.Physics.Arcade.Sprite, paddle as Phaser.Physics.Arcade.Sprite);
      },
      undefined,
      this
    );
    
    this.physics.add.collider(
      this.ball,
      this.bricks,
      (ball, brick) => {
        this.hitBrick(ball as Phaser.Physics.Arcade.Sprite, brick as Phaser.Physics.Arcade.Sprite);
      },
      undefined,
      this
    );

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
    this.input.on('pointermove', (pointer: Phaser.Input.Pointer) => {
      this.paddle.x = Phaser.Math.Clamp(
        pointer.x,
        this.paddle.width / 2,
        this.cameras.main.width - this.paddle.width / 2
      );

      if (!this.gameStarted) {
        this.ball.x = this.paddle.x;
      }
    });
    
    this.input.on('pointerdown', () => {
      if (!this.gameStarted) {
        this.gameStarted = true;
        this.ball.setVelocity(-150, -300); // 초기 x 속도를 높게 설정
      }
    });
  }

  update(): void {
    // 공이 undefined가 아닌지 확인 후 처리
    if (this.ball && this.ball.y > this.cameras.main.height) {
      this.lives--;
      this.livesText.setText(`생명: ${this.lives}`);

      if (this.lives === 0) {
        this.gameOver();
      } else {
        this.resetBall();
      }
    }
  }

  private createBricks(): void {
    const brickWidth = 64;
    const brickHeight = 32;
    const rows = 5;
    const cols = 10;
    
    // 벽돌 레이아웃을 위한 캔버스 중앙 정렬
    const offsetX = (this.cameras.main.width - (cols * brickWidth)) / 2;
    const offsetY = 80;

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const brickX = offsetX + col * brickWidth + brickWidth / 2;
        const brickY = offsetY + row * brickHeight + brickHeight / 2;
        
        // 행에 따라 다른 벽돌 이미지 사용
        const brickType = `brick${(row % 3) + 1}`;
        
        const brick = this.physics.add.sprite(brickX, brickY, brickType);
        brick.setImmovable(true);
        
        this.bricks.add(brick);
      }
    }
    
    // 왼쪽 오른쪽 벽 경계 시각화 (옵션)
    const leftWall = this.add.rectangle(0, 0, 2, this.cameras.main.height, 0x666666);
    leftWall.setOrigin(0, 0);
    const rightWall = this.add.rectangle(this.cameras.main.width - 2, 0, 2, this.cameras.main.height, 0x666666);
    rightWall.setOrigin(0, 0);
  }

  private hitBrick(
    ball: Phaser.Physics.Arcade.Sprite,
    brick: Phaser.Physics.Arcade.Sprite
  ): void {
    // ball.body가 null이 아닌지 확인
    if (!ball.body) return;
    
    // 공의 현재 속도를 벽돌 제거 전에 저장
    const velocityX = ball.body.velocity.x;
    const velocityY = ball.body.velocity.y;
    
    // 벽돌 제거
    brick.destroy();
    this.sound.play('break');
    
    // 충돌 방향 분석을 위한 계산
    const brickCenter = brick.getCenter();
    const ballCenter = ball.getCenter();
    
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
      newVelocityX = -velocityX * 1.05; // 약간 빨라지게
      
      // 공이 너무 수직으로 움직이면 각도 조정
      if (Math.abs(newVelocityY) < 60) {
        newVelocityY = newVelocityY < 0 ? -60 : 60;
      }
    } 
    // 상하측면 충돌인 경우 (수직 방향 충돌이 더 강함)
    else {
      // Y축 방향으로 튕김
      newVelocityY = -velocityY * 1.05; // 약간 빨라지게
      
      // 공이 너무 수평으로 움직이면 각도 조정
      if (Math.abs(newVelocityX) < 60) {
        newVelocityX = newVelocityX < 0 ? -60 : 60;
      }
    }
    
    // 최소 속도 보장
    const minSpeed = 100;
    const currentSpeed = Math.sqrt(newVelocityX * newVelocityX + newVelocityY * newVelocityY);
    if (currentSpeed < minSpeed) {
      const angle = Math.atan2(newVelocityY, newVelocityX);
      newVelocityX = Math.cos(angle) * minSpeed;
      newVelocityY = Math.sin(angle) * minSpeed;
    }
    
    // 최대 속도 제한
    const maxSpeed = 600;
    if (currentSpeed > maxSpeed) {
      const ratio = maxSpeed / currentSpeed;
      newVelocityX *= ratio;
      newVelocityY *= ratio;
    }
    
    // 공 속도 설정
    ball.setVelocity(newVelocityX, newVelocityY);
    
    // 점수 추가
    this.score += 10;
    this.scoreText.setText(`점수: ${this.score}`);
    
    // 모든 벽돌이 제거되면 게임 클리어
    if (this.bricks.countActive() === 0) {
      this.gameWin();
    }
  }

  private hitPaddle(
    ball: Phaser.Physics.Arcade.Sprite,
    paddle: Phaser.Physics.Arcade.Sprite
  ): void {
    this.sound.play('bounce');
    
    // 패들의 어느 부분에 맞았는지에 따라 공의 x 속도 조정
    const diff = ball.x - paddle.x;
    ball.setVelocityX(diff * 10);
  }

  private resetBall(): void {
    this.ball.setPosition(this.paddle.x, this.cameras.main.height - 100);
    this.ball.setVelocity(0, 0);
    this.gameStarted = false;
  }

  private gameOver(): void {
    this.ball.setVelocity(0, 0);
    this.gameStarted = false;
    this.sound.play('gameover');
    
    this.gameOverText.setVisible(true);
    this.restartButton.setVisible(true);
  }

  private gameWin(): void {
    this.ball.setVelocity(0, 0);
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