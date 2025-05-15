# 🧱 Brick Chain Blaster 

Brick Chain Blaster는 고전 벽돌깨기와 현대 캐주얼 게임의 다중 볼 체인 메커니즘을 결합한 퍼즐 아케이드 게임입니다.

## 📖 프로젝트 개요

- 초기 출시 플랫폼: PC 웹 (데스크톱 브라우저)
- 향후 확장: 모바일 (Android/iOS)
- 핵심 기능: 
  - 볼 체인 발사 (한 번의 조준으로 다수의 볼을 연속 발사)
  - 패턴 기반 벽돌 생성
  - 시원한 볼 애니메이션 및 패스트포워드
  - 아이템 시스템
  - 웨이브 진행형 레벨 시스템

## 🔧 기술 스택

- **프론트엔드**: Phaser 3 (TypeScript)
- **백엔드/클라우드**: Firebase (Auth, Firestore, Remote Config, Hosting)
- **결제**: Stripe Web SDK / Google Play Billing & Apple IAP 
- **모바일 래핑**: Capacitor

## 🚀 개발 로드맵

### Phase 0 – 환경 구축 & CI/CD
- Node & NPM 세팅, Phaser 템플릿 구성
- GitHub Actions → Vercel Preview URL 자동 배포

### Phase 1 – Single-Ball Block Breaker MVP
- 플레이 필드, 패들, 벽돌 충돌, 데스크톱 PWA 첫 배포
- HUD, 점수, 웨이브 루프, 게임 오버, 재시작

### Phase 2 – 멀티볼 & 페이싱 전환
- 볼 체인 발사(다중 볼), 패스트포워드 스위치
- 패턴 기반 벽돌 생성, 볼 수 증가 메커니즘

### Phase 3-5 – 확장 기능
- 온라인 및 메타 시스템, 수익화, 모바일 확장

## 🛠️ 개발 환경 설정

```bash
# Node.js 및 NPM 설치 필요

# 프로젝트 클론
git clone https://github.com/your-username/brick-chain-blaster.git
cd brick-chain-blaster

# 의존성 설치
npm install

# 개발 서버 실행
npm start

# 빌드
npm run build
```

## 📋 Task Master 사용법

이 프로젝트는 [Task Master](https://github.com/task-master-ai/task-master)를 사용하여 개발 작업을 관리합니다.

### 주요 Task Master 명령어

```bash
# 작업 목록 조회
task-master list

# 다음 작업 확인
task-master next

# 특정 작업 상세 정보 보기
task-master show <task-id>

# 작업 상태 변경
task-master set-status --id=<task-id> --status=<status>
```

## 🤝 기여 방법

1. 프로젝트 포크
2. 기능 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 푸시 (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 📄 라이선스

MIT 라이선스 적용 