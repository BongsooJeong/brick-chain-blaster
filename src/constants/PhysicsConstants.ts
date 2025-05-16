// 게임 물리 상수 정의
export const PHYSICS_CONSTANTS = {
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