# 설정 화면

`theming.md`(색·모드)와 `localization.md`(언어)가 각각 전환 **UI 일부**(앱바
아이콘)는 규정했지만, 전체 **설정 화면**(여러 항목을 모아 두는 화면 자체의
구조)은 지금까지 규정된 적이 없습니다. 그 결과 설정 화면이 있는 앱마다
컨테이너(다이얼로그/전체 페이지), 섹션 이름, "모드" 항목의 라벨이 제각각입니다.
이 문서가 그 구조를 정합니다.

## 현재 상태 (2026-10 조사)

20개 앱 중 9개만 전용 설정 화면이 있고, 나머지 11개는 앱바의 테마·언어
드롭다운 메뉴(`common/lib/settings/settings_menus.dart`)만 있습니다.

| 앱 | 컨테이너 | 섹션 | 모드 라벨 | 언어 위치 |
|---|---|---|---|---|
| daylight-flutter-studio / daylight-workbench | `AlertDialog` + 좌측 섹션 리스트 | 외형(밝기·색구성·아이콘 모양·UI 글꼴) · 편집기 · 터미널 · 병합 관문 · 환경 점검 | 밝기 | 앱바 (미포함) |
| daylight-terminal | `AlertDialog` | 새로고침 · 시작 · 관리자 권한 · 터미널 글꼴 · 터미널 색상 | — | 앱바 |
| notes2hub | `AlertDialog` | GitHub 계정 · 저장소 · 동기화 · 창 | — | 앱바 |
| snapdock | `AlertDialog` | 일반 · 단축키 · 녹화 · 저장 위치 · 메타데이터 | — | 앱바 |
| code-profiler | `Scaffold` 전체 페이지 | VS Code 경로 | — | 앱바 |
| kamailio | `Scaffold` 전체 페이지 | 서버 · 계정 · 통화 · 상주 · 화면(테마+언어 포함) | 테마 | **설정 화면 안** |
| rs485-pc-emulator | `Scaffold` 전체 페이지 | 기기 계열 · 역할 · Transport | — | 앱바 |
| saturn-mobile-client | 하드코딩 (l10n 미적용) | 단지 · 권한 · 보안 · IoT · 알림 · 통화 · 화면(테마만) · 단말정보 | 테마 | 없음 |

나머지 11개(allwinner, android-analyzer, bank-service-killer, branch-dock,
daylight-broom, daylight-commander, daylight-pdf, dove-zip, flutty-dock,
news_feeder, stevedore)는 설정 화면 자체가 없습니다.

`ui-ux.md`의 공통 단축키 표에는 이미 `설정 ⌘,`이 있어, 설정 화면을 만들
의도는 있었지만 구체화되지 않았던 것으로 보입니다.

## 규칙

### 1. 컨테이너는 지원 플랫폼으로 정한다

앱을 구상하는 **맨 처음 단계**(`conventions/README.md` 체크리스트 1번
"정체성 정하기"와 같은 시점)에 데스크톱 전용인지 모바일까지 지원하는지
정하고, 그에 따라 설정 화면 구조를 고릅니다. 둘 중 하나를 고르면 앱
생애주기 동안 바꾸지 않습니다(모바일을 나중에 추가하면 그때 전체
페이지로 옮깁니다).

| 지원 플랫폼 | 구조 | 기준 구현 |
|---|---|---|
| **데스크톱 전용** (macOS/Windows/Linux만) | `AlertDialog` + 좌측 섹션 리스트. 앱바 설정 아이콘이나 `⌘,`/`Ctrl+,`로 연다 | `daylight-flutter-studio/lib/ui/settings_dialog.dart`의 `enum SettingsSection` 패턴 |
| **모바일 포함** (android/ios 폴더가 하나라도 있음) | `Scaffold` 전체 페이지(별도 라우트) | `kamailio-sip-client/lib/ui/settings_screen.dart` |

데스크톱 전용 앱에 모바일 전용 위젯(`SegmentedButton` 풀폭 등)을 쓰지
않고, 모바일 포함 앱에 모달 다이얼로그를 쓰지 않습니다 — 창 크기와 터치
타깃이 다르기 때문입니다(`ui-ux.md` §4 밀도 표 참고).

### 2. 진입 경로: 설정 아이콘 하나로 통합

- 앱바 오른쪽의 테마·언어 **순환 아이콘은 제거**합니다. 테마와 언어는
  설정 화면 안 "외형" 섹션으로 들어갑니다(§3).
- 대신 설정 아이콘(`Icons.settings_rounded`, 단축키 `⌘,`/`Ctrl+,`) 하나를
  둡니다. 앱바 오른쪽 끝 버튼 순서는 `… | 설정 | 정보`로 바뀝니다
  (`theming.md` §3, `conventions/README.md` 체크리스트 7번의
  `테마 | 언어 | 정보`를 대체).
- 설정 화면이 없는 11개 앱도 설정 아이콘을 추가할 때 이 문서의 구조를
  바로 따릅니다 — 과거의 "앱바 테마/언어 아이콘만" 상태로 새로 만들지
  않습니다.

### 3. "외형" 섹션: 모든 앱 공통, 항상 첫 섹션

항목 순서는 고정입니다. 앱 고유 섹션(편집기, 터미널, 계정 등)은 "외형"
다음에 둡니다.

| 항목 | 라벨 | 값 | 비고 |
|---|---|---|---|
| 1 | **모드** | 시스템 설정 따르기 / 라이트 / 다크 | "밝기"·"테마" 대신 **"모드"로 통일**. `theme_mode` 키, `ThemeMode.name` |
| 2 | **색 구성** | 새턴 / 청록 / 호박 / 장미 / 슬레이트 / 고대비 | §4. 모든 앱 필수 |
| 3 | **언어** | 시스템 설정 따르기 / 한국어 / English | `localization.md`를 그대로 따르되 위치만 설정 화면으로 이동 |
| 4 (선택) | 아이콘 모양 | 둥근 / 윤곽선 / 채움 | UI 아이콘 세트가 여러 개인 앱만. 없으면 항목 자체를 생략(비활성 표시 금지) |
| 5 (선택) | UI 글꼴 + 글자 크기 배율 | 글꼴 드롭다운, 배율 슬라이더(50–150%) | `text_scale` 키. 없으면 항목 생략 |

4·5번은 지금 daylight-flutter-studio에만 있는 실험적 기능입니다.
다른 앱은 당장 구현하지 않아도 되지만, 구현할 때는 이 라벨과 순서를
그대로 씁니다.

### 4. 색 구성 팔레트 (공식 컨벤션으로 채택)

`theming.md`가 정한 "Saturn 팔레트"는 그대로 **기본값**이고, 여기에 5가지
선택지를 더합니다. `ColorScheme`의 `primary`/`primaryDeep`만 바꾸고
나머지 토큰(배경·표면·텍스트 등)은 공통입니다. 단, **고대비**는 배경·글자·
테두리까지 최대 대비로 바꿉니다.

| 팔레트 | 다크 주색 | 라이트 주색 |
|---|---|---|
| 새턴 (기본) | `#4C9DFF` | `#2C6BE0` |
| 청록 | `#2DD4BF` | `#0F766E` |
| 호박 | `#FBBF24` | `#B45309` |
| 장미 | `#FB7185` | `#BE123C` |
| 슬레이트 | `#94A3B8` | `#475569` |
| 고대비 | `#FFD60A` | `#0000CC` |

기준 구현: `daylight-flutter-studio/lib/theme/app_theme.dart`의
`enum StudioPalette`. 이 파일을 `common/lib/theme/app_theme.dart`로
역이식하는 것이 다음 작업입니다(§6).

저장 키는 `accent_palette`(값은 enum name)로 통일합니다. 앱 고유 의미
색(파일 종류 색 등)은 팔레트 전환과 무관하게 유지합니다.

### 5. 모바일 — 지금까지의 `SegmentedButton`

`theming.md`/`localization.md`가 정한 모바일용 `ThemeSegmentedButton`·
`LanguageSegmentedButton`은 그대로 쓰되, **설정 화면의 "외형" 섹션
맨 위**에 배치합니다(saturn-mobile 방식이 아니라 kamailio 방식). 모바일도
색 구성(§4)을 같은 섹션에 추가합니다.

### 6. 남은 작업 (🟡 TODO)

- `common/lib/settings/`에 이 구조의 공통 다이얼로그/페이지 뼈대를
  추가합니다 (`SettingsSection` 추상화, 섹션 리스트 위젯). 지금은 각 앱이
  `settings_dialog.dart`를 처음부터 다시 구현합니다.
- `StudioPalette`를 `common/lib/theme/app_theme.dart`로 옮기고 이름을
  `AccentPalette`로 정리합니다(studio 전용 이름을 공통 이름으로).
- `ui-ux.md` §7 단축키 표와 `conventions/README.md` 체크리스트 7번의
  `테마 | 언어 | 정보`를 `설정 | 정보`로 고칩니다(별도 커밋에서 §2 반영 시
  같이 수정).

## 관련 문서

[theming.md](theming.md) · [localization.md](localization.md) ·
[ui-ux.md](ui-ux.md) · [survey-2026-09.md](survey-2026-09.md)
