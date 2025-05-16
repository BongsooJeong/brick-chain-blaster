import Phaser from 'phaser';
import { LoadingScene } from './scenes/LoadingScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { GameScene } from './scenes/GameScene';
import './styles/main.css';

// 개발 환경에서 디버그 모드 활성화 (D 키로 토글 가능)
const DEBUG_PHYSICS = false;

// 해상도 설정
const DEFAULT_WIDTH = 800;
const DEFAULT_HEIGHT = 600;

// 사용자 기기의 화면 비율에 따라 게임 해상도를 조정하는 함수
const getGameDimensions = () => {
  // 모바일 기기에서 상대적으로 작은 해상도 사용
  if (window.innerWidth < 600) {
    return {
      width: 400,
      height: 600
    };
  }
  
  // 데스크톱 기기에서 기본 해상도 사용
  return {
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT
  };
};

// 게임 크기 계산
const gameDimensions = getGameDimensions();

const gameConfig: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#000',
  scale: {
    mode: Phaser.Scale.FIT,
    width: gameDimensions.width,
    height: gameDimensions.height,
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
      tileBias: 16,       // 타일맵 충돌 보정 값
      overlapBias: 4,     // 겹침 감지 보정 값
      forceX: false,      // X축 속도 강제 적용 비활성화
      fixedStep: true,    // 고정 시간 단계 사용 (성능과 일관성을 위해)
      useTree: true       // 공간 분할 트리 사용 (충돌 감지 최적화)
    }
  },
  render: {
    pixelArt: false,
    antialias: true,
    powerPreference: 'high-performance', // GPU 성능 우선
    batchSize: 2048       // 렌더링 배치 크기 증가 (기본값은 4096, 낮추면 드로우콜이 줄어 성능 향상)
  },
  scene: [LoadingScene, MainMenuScene, GameScene],
  // 성능 관련 글로벌 설정
  banner: false,         // 콘솔에 Phaser 배너 표시 비활성화
  disableContextMenu: true, // 게임 내 컨텍스트 메뉴 비활성화 (우클릭)
  transparent: false     // 투명 배경 사용하지 않음 (성능 향상)
};

// 창 크기 변경 이벤트에 대한 대응
window.addEventListener('resize', () => {
  if (game) {
    // 게임 크기를 다시 계산하고 업데이트
    const newDimensions = getGameDimensions();
    game.scale.resize(newDimensions.width, newDimensions.height);
  }
});

// 게임 인스턴스 생성
let game: Phaser.Game;

window.addEventListener('load', () => {
  game = new Phaser.Game(gameConfig);
  
  // 게임 디버그 정보를 전역 객체에 추가 (콘솔에서 디버깅용)
  (window as any).__PHASER_GAME__ = game;
}); 