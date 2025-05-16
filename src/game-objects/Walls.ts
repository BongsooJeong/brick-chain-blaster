import Phaser from 'phaser';

export class Walls {
  private scene: Phaser.Scene;
  private topWall: Phaser.GameObjects.Rectangle;
  private leftWall: Phaser.GameObjects.Rectangle;
  private rightWall: Phaser.GameObjects.Rectangle;
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    
    // 월드 경계 두께
    const wallThickness = 4;
    const wallColor = 0x6666aa;
    
    // 상단 벽 (충돌 영역)
    this.topWall = scene.add.rectangle(
      0, 
      0, 
      scene.cameras.main.width, 
      wallThickness, 
      wallColor
    );
    this.topWall.setOrigin(0, 0);
    
    // 왼쪽 벽 (충돌 영역)
    this.leftWall = scene.add.rectangle(
      0, 
      0, 
      wallThickness, 
      scene.cameras.main.height, 
      wallColor
    );
    this.leftWall.setOrigin(0, 0);
    
    // 오른쪽 벽 (충돌 영역)
    this.rightWall = scene.add.rectangle(
      scene.cameras.main.width - wallThickness, 
      0, 
      wallThickness, 
      scene.cameras.main.height, 
      wallColor
    );
    this.rightWall.setOrigin(0, 0);
    
    // 물리 바디 추가
    scene.physics.add.existing(this.topWall, true);
    scene.physics.add.existing(this.leftWall, true);
    scene.physics.add.existing(this.rightWall, true);
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