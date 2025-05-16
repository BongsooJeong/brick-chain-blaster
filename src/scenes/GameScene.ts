import Phaser from 'phaser';

// 게임 물리 상수 정의
const PHYSICS_CONSTANTS = {
  // 공 관련 물리 상수
  BALL: {
    INITIAL_VELOCITY: { x: -150, y: -300 },  // 공의 초기 속도
    MAX_VELOCITY: 600,                       // 공의 최대 속도
    MIN_VELOCITY: 100,                       // 공의 최소 속도
    ACCELERATION_FACTOR: 1.05,               // 공의 속도 증가 계수 (매 충돌마다)
    RESTITUTION: 1,                          // 공의 반발 계수 (1 = 완전 탄성)
    ANGULAR_VELOCITY: 60                     // 공의 회전 속도
  },
  // 패들 관련 물리 상수
  PADDLE: {
    MOVEMENT_SPEED: 800                      // 패들 이동 속도
  }
};

export class GameScene extends Phaser.Scene {
  private paddle!: Phaser.Physics.Arcade.Sprite;
  private ball!: Phaser.Physics.Arcade.Sprite;
  private bricks!: Phaser.Physics.Arcade.Group;
  private scoreText!: Phaser.GameObjects.Text;
  private livesText!: Phaser.GameObjects.Text;
  private gameOverText!: Phaser.GameObjects.Text;
  private restartButton!: Phaser.GameObjects.Text;
  
  // 벽 요소들
  private topWall!: Phaser.GameObjects.Rectangle;
  private leftWall!: Phaser.GameObjects.Rectangle;
  private rightWall!: Phaser.GameObjects.Rectangle;
  
  // 디버그 관련 요소
  private debugText!: Phaser.GameObjects.Text;
  private isDebugMode: boolean = false;
  private fpsCounter!: Phaser.GameObjects.Text;
  
  // 게임 상태 변수
  private score = 0;
  private lives = 3;
  private gameStarted = false;
  private lastTime = 0;  // 프레임 간 시간 측정용

  constructor() {
    super('GameScene');
  }

  create(): void {
    // 배경 이미지 추가
    this.add.image(0, 0, 'background')
      .setOrigin(0)
      .setDisplaySize(this.cameras.main.width, this.cameras.main.height);

    // 게임 필드 경계 생성 (시각적 요소만)
    this.createWorldBoundaries();
    
    // 디버그 모드 설정
    this.setupDebugMode();

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

    // 공 생성 및 물리 속성 설정
    this.createBall();

    // 벽돌 그룹 생성
    this.bricks = this.physics.add.group();
    this.createBricks();

    // 모든 게임 객체가 생성된 후 충돌 설정
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
        this.launchBall();
      }
    });
    
    // 디버그 모드 토글 키 설정
    this.input.keyboard?.addKey('D').on('down', () => {
      this.toggleDebugMode();
    });
    
    // 키보드 입력 설정
    this.input.keyboard?.addKey('SPACE').on('down', () => {
      if (!this.gameStarted) {
        this.gameStarted = true;
        this.launchBall();
      }
    });
    
    // 초기 시간 설정
    this.lastTime = this.time.now;
  }

  update(time: number, delta: number): void {
    // 공이 하단 경계 아래로 떨어졌는지 확인 (공이 유효하고 활성화된 경우만)
    if (this.ball && this.ball.active && this.ball.y > this.cameras.main.height) {
      this.handleBallFall();
    }
    
    // 프레임 레이트 독립적인 물리 업데이트
    if (this.gameStarted && this.ball.active) {
      this.updateBallPhysics(delta);
    }
    
    // FPS 업데이트
    if (this.isDebugMode && this.fpsCounter) {
      this.fpsCounter.setText(`FPS: ${Math.round(this.game.loop.actualFps)}`);
    }
    
    // 디버그 정보 업데이트
    if (this.isDebugMode && this.debugText && this.ball.body) {
      const velocity = this.ball.body.velocity;
      const speed = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
      
      this.debugText.setText(
        `공 속도: X=${Math.round(velocity.x)}, Y=${Math.round(velocity.y)}\n` +
        `공 위치: X=${Math.round(this.ball.x)}, Y=${Math.round(this.ball.y)}\n` +
        `속력: ${Math.round(speed)}, 최대: ${PHYSICS_CONSTANTS.BALL.MAX_VELOCITY}`
      );
    }
  }

  private createBall(): void {
    // 공 스프라이트 생성
    this.ball = this.physics.add.sprite(
      this.cameras.main.width / 2,
      this.cameras.main.height - 100,
      'ball'
    );
    
    // 공의 물리 속성 설정
    this.ball.setCollideWorldBounds(true);
    
    // 공이 가장자리에서 벗어날 경우 이벤트 설정
    if (this.ball.body) {
      // 이벤트 리스너 설정
      this.physics.world.on('worldbounds', this.onWorldBounds, this);
    }
    
    // 공의 추가 물리 속성 설정
    if (this.ball.body) {
      // 반발 계수 설정
      this.ball.body.bounce.set(PHYSICS_CONSTANTS.BALL.RESTITUTION);
      
      // 중력 영향 없음
      this.ball.body.gravity.set(0, 0);
      
      // 공 회전 설정
      this.ball.setAngularVelocity(PHYSICS_CONSTANTS.BALL.ANGULAR_VELOCITY);
    }
  }
  
  private launchBall(): void {
    // 초기 속도로 공 발사
    this.ball.setVelocity(
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.x,
      PHYSICS_CONSTANTS.BALL.INITIAL_VELOCITY.y
    );
  }
  
  private updateBallPhysics(delta: number): void {
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
  
  private onWorldBounds(body: Phaser.Physics.Arcade.Body, up: boolean, down: boolean, left: boolean, right: boolean): void {
    // 공이 세계 경계에 부딪혔을 때 처리
    if (body.gameObject !== this.ball) return;
    
    // 위, 왼쪽, 오른쪽 경계에 부딪힌 경우 사운드 재생
    if (up || left || right) {
      // 부딪힌 방향에 따라 다른 사운드 효과 적용
      let detune = 0;
      if (up) detune = -200;
      this.sound.play('bounce', { volume: 0.5, detune });
    }
    
    // 디버그 모드에서 추가 정보 표시
    if (this.isDebugMode) {
      let direction = 'unknown';
      if (up) direction = '상';
      if (down) direction = '하';
      if (left) direction = '좌';
      if (right) direction = '우';
      
      console.log(`세계 경계 충돌: ${direction}`);
    }
  }
  
  private createWorldBoundaries(): void {
    // 월드 경계 두께
    const wallThickness = 4;
    const wallColor = 0x6666aa;
    
    // 상단 벽 (충돌 영역)
    this.topWall = this.add.rectangle(
      0, 
      0, 
      this.cameras.main.width, 
      wallThickness, 
      wallColor
    );
    this.topWall.setOrigin(0, 0);
    
    // 왼쪽 벽 (충돌 영역)
    this.leftWall = this.add.rectangle(
      0, 
      0, 
      wallThickness, 
      this.cameras.main.height, 
      wallColor
    );
    this.leftWall.setOrigin(0, 0);
    
    // 오른쪽 벽 (충돌 영역)
    this.rightWall = this.add.rectangle(
      this.cameras.main.width - wallThickness, 
      0, 
      wallThickness, 
      this.cameras.main.height, 
      wallColor
    );
    this.rightWall.setOrigin(0, 0);
    
    // 월드 경계 설정 검증
    console.log('세계 경계 설정 완료', this.physics.world.bounds);
  }
  
  private setupCollisions(): void {
    // 공과 벽 사이의 충돌 설정 - 벽 요소 하나씩 개별 충돌 설정
    const walls = [this.topWall, this.leftWall, this.rightWall];
    const wallNames = ['상단', '좌측', '우측'];
    
    // 각 벽마다 개별적으로 충돌 설정
    walls.forEach((wall, index) => {
      // 개별 벽에 물리 바디 추가
      this.physics.add.existing(wall, true); // true = 정적 바디
      
      // 공과 개별 벽 사이의 충돌 설정
      this.physics.add.collider(
        this.ball, 
        wall, 
        () => {
          // 충돌 사운드 재생 (벽에 따라 다른 효과)
          const detune = index === 0 ? -200 : 0; // 상단 벽은 다른 음조
          this.sound.play('bounce', { volume: 0.5, detune });
          
          // 디버그 모드일 때 충돌 정보 표시
          if (this.isDebugMode) {
            console.log(`벽 충돌: ${wallNames[index]}`);
          }
        }
      );
    });
    
    // 공과 패들 사이의 충돌
    this.physics.add.collider(
      this.ball,
      this.paddle,
      (ball, paddle) => {
        this.hitPaddle(ball as Phaser.Physics.Arcade.Sprite, paddle as Phaser.Physics.Arcade.Sprite);
      },
      undefined,
      this
    );
    
    // 공과 벽돌 사이의 충돌
    this.physics.add.collider(
      this.ball,
      this.bricks,
      (ball, brick) => {
        this.hitBrick(ball as Phaser.Physics.Arcade.Sprite, brick as Phaser.Physics.Arcade.Sprite);
      },
      undefined,
      this
    );
  }
  
  private setupDebugMode(): void {
    // 디버그 텍스트 초기화
    this.debugText = this.add.text(
      16, 
      this.cameras.main.height - 80, 
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
    this.fpsCounter = this.add.text(
      16, 
      this.cameras.main.height - 40, 
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
    const debugHelpText = this.add.text(
      this.cameras.main.width - 16, 
      this.cameras.main.height - 16, 
      'D키: 디버그 토글', 
      {
        fontFamily: 'Arial',
        fontSize: '12px',
        color: '#aaaaaa'
      }
    ).setOrigin(1, 1);
  }
  
  private toggleDebugMode(): void {
    this.isDebugMode = !this.isDebugMode;
    
    // 물리 디버그 토글
    this.physics.world.drawDebug = this.isDebugMode;
    this.physics.world.debugGraphic.clear();
    
    // 디버그 UI 요소 가시성 토글
    this.debugText.setVisible(this.isDebugMode);
    this.fpsCounter.setVisible(this.isDebugMode);
    
    console.log(`디버그 모드: ${this.isDebugMode ? '켜짐' : '꺼짐'}`);
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
    
    // 패들 충돌 물리 로직 개선
    // 1. 패들 중앙에서 떨어진 거리에 비례하여 반사 각도 결정
    const paddleWidth = paddle.width;
    const normalizedDiff = diff / (paddleWidth / 2); // -1.0 ~ 1.0 범위로 정규화
    
    // 2. 기본 Y 속도 (항상 위쪽으로)
    const upwardVelocity = -300;
    
    // 3. 패들 타격 위치에 따른 X 속도 계산 (좌우 각도 조절)
    const horizontalVelocity = normalizedDiff * 300; // 최대 좌우 속도 ±300
    
    // 4. 최종 속도 설정 (이전 속도와 새로운 속도 병합)
    ball.setVelocity(horizontalVelocity, upwardVelocity);
    
    // 5. 패들 히트 시 속도 미세 증가 (난이도 상승)
    const currentVelocity = ball.body?.velocity;
    if (currentVelocity) {
      const speed = Math.sqrt(currentVelocity.x * currentVelocity.x + currentVelocity.y * currentVelocity.y);
      const newSpeed = Math.min(speed * PHYSICS_CONSTANTS.BALL.ACCELERATION_FACTOR, PHYSICS_CONSTANTS.BALL.MAX_VELOCITY);
      
      if (newSpeed > speed) {
        const factor = newSpeed / speed;
        ball.setVelocity(currentVelocity.x * factor, currentVelocity.y * factor);
      }
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