import Phaser from 'phaser';

export class BackgroundManager {
  private scene: Phaser.Scene;
  private background: Phaser.GameObjects.TileSprite | Phaser.GameObjects.Image;
  private gridGraphics: Phaser.GameObjects.Graphics;
  
  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.gridGraphics = scene.add.graphics();
    
    // 배경 생성 시도 - 이미지가 있으면 이미지 사용, 없으면 그라데이션 생성
    if (scene.textures.exists('background')) {
      // 이미지 배경 사용
      this.background = scene.add.tileSprite(
        0, 0,
        scene.cameras.main.width,
        scene.cameras.main.height,
        'background'
      ).setOrigin(0, 0);
    } else {
      // 이미지가 없는 경우 그라데이션 배경 생성
      this.background = this.createGradientBackground();
    }
    
    // 게임 그리드 생성
    this.createGrid();
  }
  
  // 그라데이션 배경 생성
  private createGradientBackground(): Phaser.GameObjects.Image {
    const width = this.scene.cameras.main.width;
    const height = this.scene.cameras.main.height;
    
    // 캔버스 생성 및 그라데이션 그리기
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    
    const ctx = canvas.getContext('2d')!;
    
    // 그라데이션 생성
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, '#0a0a2a'); // 상단 색상 (어두운 파란색)
    gradient.addColorStop(1, '#1a1a4a'); // 하단 색상 (조금 더 밝은 파란색)
    
    // 배경 채우기
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
    
    // 캔버스를 텍스처로 변환
    const textureName = 'generatedBackground';
    if (this.scene.textures.exists(textureName)) {
      this.scene.textures.remove(textureName);
    }
    
    this.scene.textures.addCanvas(textureName, canvas);
    return this.scene.add.image(0, 0, textureName).setOrigin(0, 0);
  }
  
  // 그리드 생성
  private createGrid(): void {
    const width = this.scene.cameras.main.width;
    const height = this.scene.cameras.main.height;
    const gridSize = 40; // 그리드 셀 크기
    const gridColor = 0x333399; // 그리드 색상
    const gridAlpha = 0.15; // 그리드 투명도
    
    this.gridGraphics.clear();
    this.gridGraphics.lineStyle(1, gridColor, gridAlpha);
    
    // 수직선 그리기
    for (let x = 0; x <= width; x += gridSize) {
      this.gridGraphics.lineBetween(x, 0, x, height);
    }
    
    // 수평선 그리기
    for (let y = 0; y <= height; y += gridSize) {
      this.gridGraphics.lineBetween(0, y, width, y);
    }
    
    // 하단 영역 구분선 (패들 위치 위)
    this.gridGraphics.lineStyle(2, 0x4444cc, 0.5);
    this.gridGraphics.lineBetween(
      0, 
      height - 100, // 패들 위치보다 약간 위
      width, 
      height - 100
    );
  }
  
  // 배경 업데이트 (필요한 경우 스크롤 등)
  public update(time: number, delta: number): void {
    // 타일 스프라이트인 경우 스크롤링 효과 (선택사항)
    if (this.background instanceof Phaser.GameObjects.TileSprite) {
      // 배경을 매우 천천히 스크롤
      this.background.tilePositionY += 0.05;
    }
  }
  
  // 토글 그리드 표시
  public toggleGrid(visible: boolean): void {
    this.gridGraphics.setVisible(visible);
  }
  
  // 오버레이 효과 추가 (예: 게임 일시 정지 시 어두워지는 효과)
  public addOverlay(alpha: number = 0.5): Phaser.GameObjects.Rectangle {
    const width = this.scene.cameras.main.width;
    const height = this.scene.cameras.main.height;
    
    const overlay = this.scene.add.rectangle(
      width / 2, 
      height / 2,
      width,
      height,
      0x000000,
      alpha
    );
    
    return overlay;
  }
} 