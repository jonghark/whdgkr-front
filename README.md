# whdgkr-front

TripSplite 앱의 Flutter 프론트엔드

## 기술 스택
- Flutter
- Riverpod (상태 관리)
- go_router (라우팅)

## 실행 방법
```bash
flutter pub get
flutter run
```

## 책임 범위
- 화면(UI)
- 사용자 입력 처리
- API 호출
- 상태 관리
- UI/UX 로직

## UI 정책 (2026-01-07 기준)

### 반응형 레이아웃
- Desktop(macOS) 포함 전체 화면 폭 대응
- 가로 폭 제한 제거 (Center/ConstrainedBox 미사용)
- 화면 가로 확장 시 이너 화면도 함께 확장
- 모바일/데스크탑 동일 로직, 레이아웃만 반응형 처리

### Overflow 방지 처리
- SafeArea + SingleChildScrollView 적용
- FloatingActionButton 하단 여백 확보 (bottom padding: 96)
- Bottom overflow 미발생 보장

## Git 관리 정책
- `build/` 디렉토리 Git ignore 처리
- `**/*.class.uniqueId*` 파일 Git ignore 처리
- 불필요한 빌드 결과물 커밋 금지

## 프로젝트 구조
```
whdgkr-front/
├── lib/
│   ├── core/           # 테마, 상수
│   ├── data/           # 모델, 레포지토리
│   └── presentation/   # 화면, 위젯, 프로바이더
├── android/
├── ios/
├── macos/
└── web/
```

---
*2026-01-07 기준 모든 프롬프트 적용 완료*
