import Phaser from 'phaser';
import { LoadingScene } from './scenes/LoadingScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { GameScene } from './scenes/GameScene';
import './styles/main.css';

const gameConfig: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#000',
  scale: {
    mode: Phaser.Scale.RESIZE,
    width: 800,
    height: 600,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false
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