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
        this.ball.setVelocity(-75, -300);
      }
    });
  }

  update(): void {
    // 공이 화면 하단으로 떨어지면 생명 감소 또는 게임 오버
    if (this.ball.y > this.cameras.main.height) {
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
  }

  private hitBrick(
    _ball: Phaser.Physics.Arcade.Sprite,
    brick: Phaser.Physics.Arcade.Sprite
  ): void {
    brick.destroy();
    this.sound.play('break');
    
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