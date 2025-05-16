import Phaser from 'phaser';
import { LoadingScene } from './scenes/LoadingScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { GameScene } from './scenes/GameScene';
import './styles/main.css';

// 개발 환경에서 디버그 모드 활성화
const DEBUG_PHYSICS = false;

const gameConfig: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#000',
  scale: {
    mode: Phaser.Scale.FIT,
    width: 800,
    height: 600,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: DEBUG_PHYSICS,
      // 물리 엔진 최적화 설정
      fps: 60,            // 물리 업데이트 속도
      timeScale: 1,       // 물리 시간 스케일 (1 = 정상 속도)
      tileBias: 16,        // 타일맵 충돌 보정 값
      overlapBias: 4,      // 겹침 감지 보정 값 
    }
  },
  render: {
    pixelArt: false,
    antialias: true
  },
  scene: [LoadingScene, MainMenuScene, GameScene]
};

// 게임 인스턴스 생성
window.addEventListener('load', () => {
  const game = new Phaser.Game(gameConfig);
}); 