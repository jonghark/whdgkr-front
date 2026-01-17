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

### macOS 실행 시 포그라운드 문제 해결
macOS에서 `flutter run -d macos` 실행 시 "Failed to foreground app; open returned 1" 에러가 발생하는 경우:

```bash
# 자동 진단 및 복구 스크립트 실행
./tools/macos_launch_fix.sh
```

이 스크립트는:
1. 앱이 실행 중인지 확인
2. 실행 중이면 포그라운드로 activate 시도
3. activate 실패 시 프로세스 종료 후 재실행 안내
4. 실행되지 않은 경우 원인 진단 (crash, LaunchServices 캐시 등)

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
- 동행자 추가 시 친구 목록에서 선택 기능
  - "친구에서 추가" 버튼 추가
  - 친구 검색 (이름/전화번호/이메일)
  - 이미 등록된 동행자는 "이미 등록됨" 표시 및 선택 불가
  - 선택 즉시 동행자로 추가
- 지출 목록 삭제/수정 UX 개선
  - Swipe 액션: 좌측 수정(파란색), 우측 삭제(빨간색)
  - 삭제 시 확인 다이얼로그 표시
  - 섹션 헤더에 "지출 추가" 버튼 추가
  - Empty state에 "첫 지출 추가하기" 버튼 추가

---

### 2026-01-10

#### 버그 수정
- 정산 대상 0원 동행자 표시 불일치 수정
  - "정산 방법" 섹션에 "정산 완료 동행자" 영역 추가
  - 0원 동행자도 정산 대상에 명시적으로 표시
  - 여행상세/정산/정산방법 간 동행자 기준 일관성 보장
- 여행 0건일 때 '새 여행' 버튼 중복 노출 수정
  - 여행 0건: Empty State 버튼만 노출, FAB 숨김
  - 여행 1건 이상: FAB만 노출, Empty State 숨김

#### 개발자 도구
- 데이터 초기화 기능 추가 (앱 최초 설치 상태 복원)
  - 개발/테스트 전용 디버그 메뉴 추가 (kDebugMode에서만 노출)
  - 2단계 확인 다이얼로그 (데이터 삭제 경고 → 최종 확인)
  - DELETE 방식 사용 (TRUNCATE/DROP 절대 금지)
  - 현재 데이터 통계 조회 기능
  - DevRepository, DevProvider 추가

---

### 2026-01-17

#### 인증 / 보안
- 로그인 전 보호 API 호출 차단
  - TripProvider에서 미인증 시 빈 리스트 반환 (API 호출 안 함)
  - tripDetailProvider, settlementProvider: 미인증 시 "로그인 필요" 에러
  - 401 에러 스팸 방지: 토큰 없으면 조용히 넘어감

- macOS SecureStorage Keychain -34018 에러 대응
  - DEV 모드: in-memory 폴백 (앱 재실행 시 토큰 소실)
  - 릴리즈 모드: 명확한 에러 메시지 throw
  - `[SecureStorage] fallback_to_memory due to -34018` 로그

- 회원가입/로그인 API 호출 추적 로그 강화
  - `### SIGNUP_BTN_CLICK ###`, `### SIGNUP_CALL_START/DONE/FAIL ###`
  - `### HTTP_REQ/RES/ERR ###` (Dio 인터셉터)
  - 백엔드: `### SIGNUP_HIT ### uri=/api/auth/signup id=xxx email=xxx`
  - JwtAuthenticationFilter: /auth 경로 이중 안전장치

#### macOS 실행 문제 해결
- macOS "Failed to foreground app; open returned 1" 자동 진단 및 복구
  - `tools/macos_launch_fix.sh` 스크립트 추가
  - 앱 실행 여부 확인 → AppleScript activate 시도 → 실패 시 프로세스 종료
  - 원인 진단: already_running, crash_exit, launchservices_cache, focus_permission
  - `[LAUNCH_DIAG] running=true/false pid=xxx` 형식 로그
