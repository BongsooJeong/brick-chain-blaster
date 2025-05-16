import Phaser from 'phaser';

export class BrickManager {
  private scene: Phaser.Scene;
  private bricks: Phaser.Physics.Arcade.Group;
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.bricks = scene.physics.add.group();
  }
  
  // 벽돌 생성
  public createBricks(): void {
    const brickWidth = 64;
    const brickHeight = 32;
    const rows = 5;
    const cols = 10;
    
    // 벽돌 레이아웃을 위한 캔버스 중앙 정렬
    const offsetX = (this.scene.cameras.main.width - (cols * brickWidth)) / 2;
    const offsetY = 80;

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const brickX = offsetX + col * brickWidth + brickWidth / 2;
        const brickY = offsetY + row * brickHeight + brickHeight / 2;
        
        // 행에 따라 다른 벽돌 이미지 사용
        const brickType = `brick${(row % 3) + 1}`;
        
        const brick = this.scene.physics.add.sprite(brickX, brickY, brickType);
        brick.setImmovable(true);
        
        this.bricks.add(brick);
      }
    }
  }
  
  // 벽돌 그룹 가져오기
  public getGroup(): Phaser.Physics.Arcade.Group {
    return this.bricks;
  }
  
  // 활성 벽돌 수 가져오기
  public getActiveCount(): number {
    return this.bricks.countActive();
  }
} 