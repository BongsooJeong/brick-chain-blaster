import Phaser from 'phaser';

export class Walls {
  private scene: Phaser.Scene;
  private topWall: Phaser.GameObjects.Rectangle;
  private leftWall: Phaser.GameObjects.Rectangle;
  private rightWall: Phaser.GameObjects.Rectangle;
  
  // 장식용 요소 추가
  private topGlow: Phaser.GameObjects.Rectangle;
  private leftGlow: Phaser.GameObjects.Rectangle;
  private rightGlow: Phaser.GameObjects.Rectangle;
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    
    // 월드 경계 두께
    const wallThickness = 4;
    const wallColor = 0x6b88ff; // 더 밝은 파란색
    
    // 상단 벽 (충돌 영역)
    this.topWall = this.createWall(0, 0, scene.cameras.main.width, wallThickness, wallColor);
    
    // 왼쪽 벽 (충돌 영역)
    this.leftWall = this.createWall(0, 0, wallThickness, scene.cameras.main.height, wallColor);
    
    // 오른쪽 벽 (충돌 영역)
    this.rightWall = this.createWall(
      scene.cameras.main.width - wallThickness, 
      0, 
      wallThickness, 
      scene.cameras.main.height, 
      wallColor
    );
    
    // 글로우 효과 추가
    this.topGlow = this.createGlowEffect(
      0, 0, scene.cameras.main.width, wallThickness * 3, wallColor
    );
    
    this.leftGlow = this.createGlowEffect(
      0, 0, wallThickness * 3, scene.cameras.main.height, wallColor
    );
    
    this.rightGlow = this.createGlowEffect(
      scene.cameras.main.width - wallThickness * 3, 
      0, 
      wallThickness * 3, 
      scene.cameras.main.height, 
      wallColor
    );
    
    // 물리 바디 추가 (충돌 영역에만)
    scene.physics.add.existing(this.topWall, true);
    scene.physics.add.existing(this.leftWall, true);
    scene.physics.add.existing(this.rightWall, true);
    
    // 글로우 효과 애니메이션
    this.setupGlowAnimations();
  }
  
  // 벽 생성 헬퍼 함수
  private createWall(
    x: number, 
    y: number, 
    width: number, 
    height: number, 
    color: number
  ): Phaser.GameObjects.Rectangle {
    const wall = this.scene.add.rectangle(x, y, width, height, color);
    wall.setOrigin(0, 0);
    return wall;
  }
  
  // 글로우 효과 생성 헬퍼 함수
  private createGlowEffect(
    x: number, 
    y: number, 
    width: number, 
    height: number, 
    color: number
  ): Phaser.GameObjects.Rectangle {
    const glow = this.scene.add.rectangle(x, y, width, height, color, 0.3);
    glow.setOrigin(0, 0);
    glow.setBlendMode(Phaser.BlendModes.ADD);
    return glow;
  }
  
  // 글로우 효과 애니메이션 설정
  private setupGlowAnimations(): void {
    // 상단 글로우 애니메이션
    this.scene.tweens.add({
      targets: this.topGlow,
      alpha: { from: 0.1, to: 0.3 },
      duration: 1500,
      ease: 'Sine.easeInOut',
      yoyo: true,
      repeat: -1
    });
    
    // 왼쪽/오른쪽 글로우 애니메이션
    this.scene.tweens.add({
      targets: [this.leftGlow, this.rightGlow],
      alpha: { from: 0.1, to: 0.3 },
      duration: 2000,
      ease: 'Sine.easeInOut',
      yoyo: true,
      repeat: -1,
      delay: 500 // 상단과 약간 다른 타이밍
    });
  }
  
  // 벽 객체 배열 반환
  public getWalls(): Phaser.GameObjects.Rectangle[] {
    return [this.topWall, this.leftWall, this.rightWall];
  }
  
  // 벽 이름 배열 반환 (디버그용)
  public getWallNames(): string[] {
    return ['상단', '좌측', '우측'];
  }
  
  // 개별 벽 반환
  public getTopWall(): Phaser.GameObjects.Rectangle {
    return this.topWall;
  }
  
  public getLeftWall(): Phaser.GameObjects.Rectangle {
    return this.leftWall;
  }
  
  public getRightWall(): Phaser.GameObjects.Rectangle {
    return this.rightWall;
  }
} 