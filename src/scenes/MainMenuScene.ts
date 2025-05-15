import Phaser from 'phaser';

export class MainMenuScene extends Phaser.Scene {
  private titleText!: Phaser.GameObjects.Text;
  private startButton!: Phaser.GameObjects.Image;

  constructor() {
    super('MainMenuScene');
  }

  create(): void {
    // 배경 이미지 추가
    this.add.image(0, 0, 'background')
      .setOrigin(0)
      .setDisplaySize(this.cameras.main.width, this.cameras.main.height);

    // 게임 타이틀
    this.titleText = this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 4,
      'Brick Chain Blaster',
      {
        fontFamily: 'Arial',
        fontSize: '48px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 4,
        shadow: { color: '#000000', blur: 10, stroke: true, fill: true }
      }
    ).setOrigin(0.5);

    // 시작 버튼
    this.startButton = this.add.image(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2 + 100,
      'button'
    ).setInteractive({ useHandCursor: true });

    // 시작 버튼 텍스트
    this.add.text(
      this.cameras.main.width / 2,
      this.cameras.main.height / 2 + 100,
      '게임 시작',
      {
        fontFamily: 'Arial',
        fontSize: '24px',
        color: '#ffffff'
      }
    ).setOrigin(0.5);

    // 시작 버튼 이벤트
    this.startButton.on('pointerdown', () => {
      this.startGame();
    });

    // 버튼 애니메이션
    this.tweens.add({
      targets: this.startButton,
      scale: { from: 1, to: 1.1 },
      duration: 1000,
      ease: 'Sine.easeInOut',
      yoyo: true,
      repeat: -1
    });
  }

  private startGame(): void {
    this.scene.start('GameScene');
  }
} 