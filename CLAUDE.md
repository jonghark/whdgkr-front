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

## 도메인/UX 규칙

### 용어 통일
- '참가자' → '동행자'로 전면 통일

### 반응형 레이아웃
- Desktop(macOS) 포함 전체 화면 폭 대응
- 가로 폭 제한 제거 (Center/ConstrainedBox 미사용)
- 화면 가로 확장 시 이너 화면도 함께 확장
- 모바일/데스크탑 동일 로직, 레이아웃만 반응형 처리

### Overflow 방지 처리
- SafeArea + SingleChildScrollView 적용
- FloatingActionButton 하단 여백 확보 (bottom padding: 96)
- Bottom overflow 미발생 보장

### 동행자 표시 기준
- `activeParticipants` (deleteYn='N') 기준으로 카운트
- owner 포함 여부 통일

### 대표 결제자 표시
- 1명: 이름 표시
- 2명 이상: "대표이름 외 N명" (가장 많이 낸 사람, 동률 시 이름순)

## Git 관리 정책
- `build/` 디렉토리 Git ignore 처리
- `**/*.class.uniqueId*` 파일 Git ignore 처리
- 불필요한 빌드 결과물 커밋 금지

## 문서 관리 정책
- 모든 문서는 CLAUDE.md 하나로 관리
- README.md, CHANGELOG.md 별도 생성 금지
- 변경 이력은 아래 Changelog 섹션에 날짜별 누적

---

## Changelog

### 2026-01-07

#### UI / UX
- 여행 상세 화면 상하 여백 축소로 정보 밀도 개선
- 동행자 관리 버튼을 동행자 요약 영역 옆으로 이동
- 정산 요약 가시성 강화 (총 지출 하단 요약 영역 추가)
- 일정 수정 다이얼로그 UI 자연스럽게 개선
- 동행자 관리 모달 스크롤 불가 문제 수정

#### 기능 개선
- 지출 목록에 대표 결제자 표시
- 지출 수정 저장 시 404 오류 수정 (API 경로/메서드 정합성)
- 여행 상세에서 일정(시작일/종료일) 수정 가능

#### 동행자 / 친구 관리
- '참가자' 용어를 '동행자'로 전면 통일
- 동행자 입력 시 전화번호/이메일 유효성 검사 추가
- 전화번호 저장 시 숫자만 저장하도록 정규화
- 동행자 추가/삭제 후 '내 여행' 탭 즉시 반영
- 친구 관리 수정/삭제 버튼 UI 개선
- 친구 목록에서 동행자 추가 기능 제공
- 이미 등록된 동행자는 추가 불가 처리 및 "이미 등록됨" 표시

---

### 2026-01-08

#### 버그 수정
- '내 여행'과 여행 상세 간 동행자 수 불일치 오류 수정
  - delete_yn='N' 기준으로 집계 통일
  - owner 포함 기준 통일
  - Front 캐시 invalidate 보강

#### UI 개선
- 동행자 관리 바텀시트/모달 스크롤 정상화
- 키보드 노출 시 하단 영역 가림 현상 수정

#### 문서 정책
- 모든 md 파일을 CLAUDE.md로 통합

#### 기능 개선
- 여행 일정 변경 시 지출 이력 존재 구간 변경 금지
  - 지출 날짜가 새 기간 밖으로 밀려나는 변경 차단
  - "일정 변경 불가" 얼럿 다이얼로그 표시
  - Front/Backend 이중 검증으로 데이터 무결성 보장
