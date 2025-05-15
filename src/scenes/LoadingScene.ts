import Phaser from 'phaser';

export class LoadingScene extends Phaser.Scene {
  private loadingBar!: Phaser.GameObjects.Graphics;
  private progressBar!: Phaser.GameObjects.Graphics;
  private loadingText!: Phaser.GameObjects.Text;

  constructor() {
    super('LoadingScene');
  }

  preload(): void {
    this.cameras.main.setBackgroundColor('#000000');
    this.createLoadingGraphics();

    // 로딩 이벤트 리스너 등록
    this.load.on('progress', (value: number) => {
      this.progressBar.clear();
      this.progressBar.fillStyle(0xffffff, 1);
      this.progressBar.fillRect(
        this.cameras.main.width / 4,
        this.cameras.main.height / 2 - 16,
        (this.cameras.main.width / 2) * value,
        32
      );
      this.loadingText.setText(`로딩 중... ${Math.round(value * 100)}%`);
    });

    this.load.on('complete', () => {
      this.progressBar.destroy();
      this.loadingBar.destroy();
      this.loadingText.destroy();
      this.scene.start('MainMenuScene');
    });

    // 임시 에셋 로딩 (실제 게임 개발시 이미지 로드)
    this.loadAssets();
    
    // 로딩 시간 시뮬레이션 (실제 게임에서는 제거)
    for (let i = 0; i < 100; i++) {
      this.load.image(`temp${i}`, 'about:blank');
    }
  }

  private createLoadingGraphics(): void {
    this.loadingText = this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2 - 50,
      '로딩 중... 0%',
      {
        fontFamily: 'Arial',
        fontSize: '24px',
        color: '#ffffff'
      }
    ).setOrigin(0.5);
    
    this.loadingBar = this.add.graphics();
    this.loadingBar.fillStyle(0x444444, 1);
    this.loadingBar.fillRect(
      this.cameras.main.width / 4 - 2,
      this.cameras.main.height / 2 - 18,
      this.cameras.main.width / 2 + 4,
      36
    );
    
    this.progressBar = this.add.graphics();
  }

  private loadAssets(): void {
    this.createTemporaryImages();
    
    this.load.image('background', 'assets/images/background.png');
    this.load.image('ball', 'assets/images/ball.png');
    this.load.image('paddle', 'assets/images/paddle.png');
    this.load.image('brick1', 'assets/images/brick1.png');
    this.load.image('brick2', 'assets/images/brick2.png');
    this.load.image('brick3', 'assets/images/brick3.png');
    
    this.load.audio('bounce', 'assets/audio/bounce.wav');
    this.load.audio('break', 'assets/audio/break.wav');
    this.load.audio('gameover', 'assets/audio/gameover.wav');
  }

  private createTemporaryImages(): void {
    const createTempImage = (name: string, width: number, height: number, color: number) => {
      const graphics = this.make.graphics({ x: 0, y: 0 });
      graphics.fillStyle(color);
      graphics.fillRect(0, 0, width, height);
      graphics.generateTexture(name, width, height);
      graphics.destroy();
    };
    
    createTempImage('background', 800, 600, 0x000033);
    createTempImage('ball', 16, 16, 0xffffff);
    createTempImage('paddle', 128, 16, 0x0088ff);
    createTempImage('brick1', 64, 32, 0xff0000);
    createTempImage('brick2', 64, 32, 0x00ff00);
    createTempImage('brick3', 64, 32, 0x0000ff);
  }
} 