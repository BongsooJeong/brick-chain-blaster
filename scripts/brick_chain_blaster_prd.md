```
<context>
# Overview  
Brick Chain Blaster는 고전 벽돌깨기와 현대 캐주얼 게임의 다중 볼 체인 메커니즘을 결합한 퍼즐 아케이드 게임이다. 초기 출시 플랫폼은 PC 웹(데스크톱 브라우저)이며, 동일 코드베이스를 활용해 추후 모바일(Android/iOS)로 확장한다. 사용자는 마우스 오버로 조준선을 확인하고 클릭으로 여러 개의 볼을 발사하여 상단에서 내려오는 벽돌을 파괴하며, 벽돌이 화면을 가득 채우기 전에 최대한 높은 웨이브를 달성해야 한다. 짧고 중독성 강한 세션을 원하는 캐주얼 게이머에게 즉각적인 성취감과 장기적인 성장·수집·경쟁 요소를 제공한다.

# Core Features  
- 볼 체인 발사  
  - 무엇을 하나요: 한 번의 조준으로 다수의 볼을 연속 발사한다.  
  - 왜 중요한가요: 대량 타격의 시각적 쾌감과 각도 계산의 전략성을 동시에 제공한다.  
  - 작동 방식: 사용자가 조준선을 설정한 뒤 클릭하면, 다수의 볼이 일정 간격으로 연속 발사되어 물리 충돌을 일으킨다.  
- 시원한 볼 애니메이션 & 패스트포워드  
  - 무엇을 하나요: 볼 발사·충돌 애니메이션을 고프레임으로 표현하고, 버튼 한 번으로 턴을 최대 4배속으로 가속하거나 즉시 결과를 확인할 수 있다.  
  - 왜 중요한가요: 다수의 볼이 높은 HP 벽돌을 오래 때리는 상황에서 발생하는 지루함을 해소하고, 강력한 타격감을 유지한다.  
  - 작동 방식: 게임 로직과 애니메이션을 분리해, 가속 시뮬레이션이 빠르게 진행되며 화면 상단 진행 막대로 남은 시간을 시각화한다.  

- 패턴 기반 벽돌 생성  
  - 무엇을 하나요: 턴마다 패턴 라이브러리를 활용해 랜덤·규칙 조합 형태로 벽돌을 배치한다.  
  - 왜 중요한가요: 반복적인 한 줄 추가 방식에서 벗어나 시각적·전략적 다양성을 제공한다.  
  - 작동 방식: 웨이브마다 미리 정의된 패턴을 무작위로 선택·변형해 벽돌을 배치한다.  

- 벽돌 HP 시스템    
  - 무엇을 하나요: 모든 벽돌은 오직 HP 수치만 가지고 있다.  
  - 왜 중요한가요: 규칙을 단순화해 핵심 재미를 발사 각도·아이템 전략에 집중시킨다.  
  - 작동 방식: 웨이브 인덱스가 높아질수록 벽돌의 HP가 선형적으로(또는 가중치 기반) 증가한다.  
- 아이템 시스템  
  - 개요: 필드에 떠 있는 아이콘을 볼이 통과하면 수집되어 우측 인벤토리에 저장된다. 한 턴에 하나만 사용 가능하며, 사용 후 바로 소모되고 효과는 그 턴 동안만 지속된다.  
  - 작동 방식: 플레이어가 아이템 아이콘을 클릭(또는 터치)해 활성화하면, 해당 턴 동안 효과가 적용되고 종료 후 소모된다.  

- 볼 수 증가 메커니즘  
  - 무엇을 하나요: 일정 개수의 벽돌을 파괴할 때마다 자동으로 발사되는 볼 수가 +1된다.  
  - 작동 방식: 누적 파괴 카운터가 임계치에 도달하면, 다음 턴부터 발사되는 볼 수가 영구적으로 1 증가한다.  

- 라이브 운영 및 수익화  
  - 광고 리워드, IAP, 시즌 패스 등을 통해 장기적인 매출과 신선한 콘텐츠를 제공한다.  
  - 작동 방식: 서버 설정으로 이벤트와 상품을 제어하며, 플랫폼별 광고·결제 솔루션을 통합한다.  

# User Experience  
- User personas  
  - 캐주얼 통근러: 출퇴근 5분 내 게임, 광고 리워드 적극 활용.  
  - 완벽주의 수집러: 최고 웨이브와 스킨 수집, 시즌 패스 구매 잠재.  
  - 레트로 애호가: 단순 조작과 도전 난이도 선호, 광고 제거 IAP 선호.  
- Key user flows  
  1. 첫 실행 → 30초 튜토리얼 → 첫 웨이브 클리어 → 업그레이드 팝업  
  2. 일반 플레이 루프 → 웨이브 진행 → 광고 리워드 또는 부활 선택  
  3. 게임 오버 → 점수 공유 → 코인 소비 또는 시즌 패스 제안  
- UI/UX considerations  
  - 데스크톱: 마우스 커서 중심 조준선 + 휠 스크롤 UI 옵션.  
  - 모바일 확장 대비: 해상도 대응과 터치 HUD(가상 버튼) 레이어 설계.  
  - 접근성: 하이 콘트라스트 테마, 진동·사운드 보조 피드백.  

- UI/GUI Concept  
  - 선택된 컨셉: **Modern Cool** (다크 배경 + 네온 라인)  
</context>
<PRD>
# Technical Architecture  
- System components  
  - **Phaser 3** (JavaScript/TypeScript) + Arcade Physics  
  - Firebase Suite (Auth, Firestore, Remote Config, Hosting)  
  - Stripe Web SDK / Google Play Billing & Apple IAP (Capacitor plug‑ins)  
  - Capacitor (or Cordova) wrapper for native Android/iOS builds  
- Target platforms  
  - V1: PC Web (Progressive Web App)  
  - V2: 모바일 Web 및 Wrapped Android/iOS 앱  
- Development Roadmap *(Agile, Incremental)*  
  - **Phase 0 – 환경 구축 & CI/CD**  
    - Node&nbsp;+&nbsp;NPM 세팅, Phaser 템플릿 `create-phaser`  
    - GitHub Actions → Vercel Preview URL 자동 배포  
  - **Phase 1 – Single‑Ball Block Breaker MVP**  
    - *Sprint 1*: 플레이 필드·패들·벽돌 충돌, 데스크톱 PWA 첫 배포  
    - *Sprint 2*: HUD, 점수·웨이브 루프, 게임 오버·재시작  
  - **Phase 2 – 멀티볼 & 페이싱 전환**  
    - *Sprint 3*: 볼 체인 발사(다중 볼), 패스트포워드 스위치 *(Feature Toggle)*  
    - *Sprint 4*: 패턴 기반 벽돌 생성, 볼 수 증가 메커니즘  
  - **Phase 3 – 온라인 & 메타 시스템**  
    - *Sprint 5*: Firebase Auth + 클라우드 세이브, 글로벌 랭킹  
    - *Sprint 6*: 스킨·아이템 인벤토리, Remote Config 통합  
  - **Phase 4 – 수익화 & 런칭 준비**  
    - *Sprint 7*: 광고 리워드, 기본 IAP(광고 제거)  
    - *Sprint 8*: 시즌 패스 프로토타입, 밸런스 튜닝  
  - **Phase 5 – 모바일 래핑 & 스토어 출시**  
    - *Sprint 9*: Capacitor Build, 터치 HUD 최적화, 모바일 QA  
    - *Sprint 10*: 스토어 메타데이터·릴리스, LiveOps Dashboard  
- Risks & Mitigations  
  - 브라우저별 WebGL 성능 편차 → Canvas fallback 및 성능 프로파일링  
  - 모바일 메모리·터치 UX 제한 → 경량 에셋 및 반응형 UI 테스트  
  - 패키지 버전 충돌 → `npm shrinkwrap` 및 정기적 통합 테스트  
</PRD>
```
