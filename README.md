# 벽돌 체인 블라스터 (Brick Chain Blaster)

벽돌 체인 블라스터는 고전 벽돌깨기와 현대 캐주얼 게임의 다중 볼 체인 메커니즘을 결합한 퍼즐 아케이드 게임입니다.

## 게임 개요

사용자는 마우스 오버로 조준선을 확인하고 클릭으로 여러 개의 볼을 발사하여 상단에서 내려오는 벽돌을 파괴하며, 벽돌이 화면을 가득 채우기 전에 최대한 높은 웨이브를 달성해야 합니다. 짧고 중독성 강한 세션을 원하는 캐주얼 게이머에게 즉각적인 성취감과 장기적인 성장·수집·경쟁 요소를 제공합니다.

## 주요 기능

- **볼 체인 발사**: 한 번의 조준으로 다수의 볼을 연속 발사
- **물리 기반 시뮬레이션**: 탄성 충돌 기반의 현실적인 물리 시뮬레이션
- **다양한 벽돌 패턴**: 다양한 레벨과 난이도로 구성된 벽돌 패턴
- **아이템 시스템**: 게임 플레이에 전략적 요소를 추가하는 아이템
- **업그레이드 시스템**: 지속적인 성장 요소를 제공하는 업그레이드

## 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **백엔드**: Firebase (Authentication, Firestore, Storage, Functions)
- **배포**: GitHub Actions, Firebase Hosting

## 개발 환경 설정

1. Flutter 설치 (버전 3.29 이상)
2. 저장소 클론
   ```
   git clone https://github.com/BongsooJeong/brick-chain-blaster.git
   ```
3. 의존성 설치
   ```
   flutter pub get
   ```
4. 웹 브라우저에서 실행
   ```
   flutter run -d chrome
   ```

## 프로젝트 구조

```
lib/
  ├── config/        # 환경 설정 및 Firebase 구성
  ├── controllers/   # 비즈니스 로직 컨트롤러
  ├── models/        # 데이터 모델
  ├── services/      # 서비스 레이어
  ├── utils/         # 유틸리티 함수
  ├── views/         # UI 화면 컴포넌트
  └── main.dart      # 앱 진입점
```

## 라이선스

MIT 라이선스