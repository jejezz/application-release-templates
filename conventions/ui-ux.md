# UI/UX 전략

색상과 테마 모드는 [theming.md](theming.md), 글꼴은 [fonts.md](fonts.md),
UI 아이콘은 [icons.md](icons.md)에서 다룹니다. 이 문서는 그 위에서 화면을
구성하는 규칙입니다.

## 현재 상태

- Material 앱 5개(saturn, portside, allwinner, daylight, dove)가 이미 같은
  **"Saturn 디자인 언어"** 를 쓰고 있습니다. 색상 값, 모서리
  24/20/999, `GlassCard`, `StatusPill`이 같습니다.
  - 다만 토큰 파일을 저장소마다 **복사해서** 쓰고 있어 조금씩 달라지고
    있습니다. 예를 들어 dove는 daylight 테마에 `outlinedButtonTheme`과
    `snackBarTheme`을 더했고, portside는 버튼 모서리가 16입니다.
- 설계 문서가 있는 앱은 daylight(`UI_UX.md`), dove(`UI_UX.md`),
  portside(`DESIGN.md`)뿐입니다.
- 창 크기를 정하는 방식이 두 가지입니다. `window_manager`를 쓰는 앱
  (daylight, dove, MacBroom)과 Swift `minSize`로 정하는 앱(portside,
  allwinner)입니다.
- 단축키
  - 코드로 구현한 앱은 daylight와 portside입니다.
  - dove는 문서에만 적혀 있고 코드에는 없습니다.
- MacBroom만 `macos_ui` 기반의 별도 디자인입니다.

## 규칙

### 1. 디자인 언어는 하나: Saturn

- 새 앱은 Saturn 디자인 언어를 씁니다. 기준 구현은
  [`common/lib/theme/app_theme.dart`](../common/lib/theme/app_theme.dart)입니다
  (daylight → dove-zip의 테마를 이 문서와 theming.md에 맞게 정리한 것).
- `useMaterial3: true`로 두고 Material 컴포넌트를 씁니다. 모양은 테마에서
  덮어씁니다.
- 예외: 메뉴바 전용 macOS 유틸리티(MacBroom 유형)는 `macos_ui`를 써도
  됩니다. 이때도 [theming.md](theming.md)의 색 토큰 이름과 의미는 따릅니다.

### 2. 토큰은 복사하지 않고 공유한다

🟡 **TODO** — 토큰(`AppColors`, `AppRadius`, `AppSpacing`, `AppTheme`)과
공통 위젯(`GlassCard`, `StatusPill`, `showErrorSnackBar`, 정보 창)을
**Dart 패키지 하나**(`zoomon_ui`, 비공개 git 저장소)로 옮기고, 각 앱은 git
의존성으로 가져옵니다.

```yaml
dependencies:
  zoomon_ui:
    git: { url: https://github.com/jejezz/zoomon-ui-flutter, ref: v1.0.0 }
```

패키지가 생기기 전까지는 [`common/lib/`](../common/lib/)의 `theme/`,
`settings/`, `about/`을 복사합니다. 파일 첫 줄의 출처 주석은 그대로
둡니다. 연결 방법은 [`common/lib/main.dart`](../common/lib/main.dart)가 보여
줍니다.

### 3. 토큰 값

| 토큰 | 값 |
|---|---|
| 모서리 `AppRadius` | sheet 32, card 24, tile 20, button 10, iconChip 7, chip 999 |
| 간격 `AppSpacing` | 4의 배수: 4 / 8 / 12 / 16 / 24 / 32 |
| 버튼 높이 | 데스크톱 36, 모바일 44 (터치 최소 크기) |
| 포커스 링 | primary 2px (키보드 탐색이 보여야 함) |
| 유리 효과 | 반투명 채움 + 1px 테두리로 흉내 냅니다. `BackdropFilter`는 성능 문제로 쓰지 않습니다 |

### 4. 밀도: 데스크톱과 모바일을 구분

| | 데스크톱 (daylight 기준) | 모바일 (saturn 기준) |
|---|---|---|
| 본문 / 목록 행 | 13 | 15 |
| 보조 텍스트 | 11–11.5 | 13 |
| 대화상자 제목 | 16 bold | 20 bold |
| 화면 제목 | 20 w800 | 34 w800 |
| 아이콘 | 목록 22, 툴바 18, 사이드바 16, 앱 바 버튼 20 | 24 |
| 앱 바(타이틀 바) 높이 | 44 | 56 (`kToolbarHeight`) |
| 스플래시 효과 | 밀집된 목록 행은 `NoSplash` | 기본 |

앱 바 오른쪽 아이콘 버튼은 모두 같은 크기로 맞춥니다. 핵심은 "통일"이고 20은
기본값입니다. 앱 바가 낮은 앱(예: 높이 44에 18)은 그 앱의 기존 크기로 통일해도 됩니다. 크기를 지정하지
않은 버튼과 지정한 버튼이 섞이면 아이콘이 들쭉날쭉해 보입니다. 버튼 크기는
`IconButtonTheme`의 `iconSize`로 한꺼번에 정합니다.

앱 바 높이는 `AppBarTheme.toolbarHeight`(공용 `app_theme.dart`)에서 한 번만
정합니다. 화면마다 `AppBar(toolbarHeight: …)`를 따로 주지 않습니다 — 앱마다,
화면마다 타이틀 바 높이가 달라 보이는 원인이 됩니다.

창이 포커스를 받으면 앱 바 배경이 서서히 강조색으로 물들고 잃으면 빠집니다
(`lib/window/focus_tint.dart`, `AppBar(flexibleSpace: const FocusTint())`). 어느
창이 활성인지 한눈에 보이게 하려는 것이며, OS 타이틀 바와 신호등 버튼은
건드리지 않습니다. 모든 데스크톱 앱 바에 같은 위젯을 씁니다.

#### 버튼 안쪽 여백과 글자 위치

버튼 글자는 위아래 **대칭** 여백으로 가운데에 두고, 양옆은 넉넉히 둡니다.
글자가 꽉 차 보이거나 위로 쏠려 보이는 버튼은 대부분 이 둘 중 하나가 어긋난 것입니다.

| | 양옆 | 위아래 |
|---|---|---|
| 글자 버튼 | 20 (Flutter M3 기본 24) | 대칭 |
| 아이콘 + 글자 버튼 | 앞 16 · 뒤 24, 아이콘 18, 사이 8 (`FilledButton.icon`과 같음) | 대칭 |
| 촘촘한 줄(경로 줄·알림 띠·찾기 막대) 안의 버튼 | 16 | 대칭, 높이만 낮춤 |

- **Flutter**: M3 기본 버튼이 이미 이 모양입니다(글자 줄을 `Alignment.center`로 놓음).
  버튼 테마에서는 `minimumSize`·`shape`·`textStyle`만 정하고 위아래가 다른
  `padding`을 주지 않습니다.
- **Flutter가 아닌 앱(Avalonia 등)**: 툴킷 기본값을 그대로 쓰지 않습니다.
  Avalonia Fluent의 기본 `Padding`은 `8,5,8,6`이라 옆이 좁고 아래가 0.5 커서
  글자가 꽉 차고 위로 쏠려 보입니다. 공통 스타일에서 한 번에 정하고(예:
  `Button` `20,5.5,20,5.5` · `VerticalContentAlignment=Center`, 아이콘 버튼 클래스
  `16,5.5,24,5.5`, 촘촘한 줄 클래스 `16,4,16,4`), 버튼마다 `Padding`을 따로 주지
  않습니다. 위아래 합을 툴킷 기본과 같게 두면 버튼 높이가 바뀌지 않습니다.
- **글꼴 탓으로 보정하지 않습니다.** SeoulNamsan 한글은 줄 상자(hhea 위 880 ·
  아래 305) 안에서 가운데보다 약 0.1em 위에 그려지지만, Flutter도 같은 줄 상자를
  가운데에 놓으므로 두 앱에서 같은 자리에 보입니다. 위아래 여백을 다르게 주어
  "내리면" 오히려 Flutter 앱과 어긋납니다.
- 확인은 눈대중이 아니라 같은 배율의 화면 사진에서 버튼 배경과 글자 윤곽의 위아래
  끝을 재어 Flutter 앱과 비교합니다. 기준 사례: daylight-compare-avalonia(2026-11),
  Daylight PDF 버튼과 2배 화면에서 1px 안으로 맞춤.

### 5. 창 (데스크톱)

- `window_manager`로 크기, 최소 크기, 제목을 정합니다. Swift/C++ 러너
  코드에서 크기를 정하지 않습니다.
  ```dart
  const WindowOptions(size: Size(1200, 720), minimumSize: Size(960, 600),
      center: false, title: '<표시 이름>');
  ```
  시작 위치는 `center: true` 대신 `placeWindowAtStartup`으로 정합니다 — 모니터마다
  배율이 다른 Windows 듀얼 모니터에서 `center: true`가 창을 화면 밖에 놓습니다
  ([window-placement.md](window-placement.md)).
- 기본 크기: 목록·편집기 같은 작업 앱은 1200×720, 작은 유틸리티는
  960×640. 최소 크기는 **960×600 이하**로 둡니다 (1366×768 노트북에서
  잘리지 않도록).
- 마지막 창 크기와 위치를 기억하는 것은 선택 사항입니다. 마지막에 쓰던 모니터를
  기억하는 것은 [window-placement.md](window-placement.md)의 규칙을 따릅니다.
- 제목 표시줄은 OS 기본을 씁니다. 창 테두리 색을 테마와 맞추는 방법은
  [theming.md](theming.md)에 있습니다.

### 6. 화면 구조와 상태

- **빈 상태**: 48px 아이콘, 한 줄 안내, 주 행동 버튼 하나. dove의
  "드래그하거나 클릭해서 열기" 화면이 기준입니다.
- **로딩**: 0.5초 이상 걸리는 작업만 진행 표시를 합니다. 오래 걸리는 작업은
  진행률과 취소 버튼을 함께 보여줍니다.
- **오류**: `showErrorSnackBar`로 알리고, 오류 원문을 복사할 수 있는
  "복사" 액션을 붙입니다 (dove 구현). 치명적 오류만 대화상자로 띄웁니다.
- **확인 대화상자**: 되돌릴 수 없는 작업(삭제, 덮어쓰기, 포맷)에만 띄웁니다.
  위험한 버튼은 `error` 색 FilledButton이고, 기본 포커스는 취소에 둡니다.
- **완료 알림**: 스낵바 또는 토스트로, 4초 후 자동으로 닫습니다.

### 7. 입력 (데스크톱)

- **키보드 우선**: 모든 주요 기능은 단축키로 쓸 수 있어야 합니다.
  `Shortcuts` / `CallbackShortcuts`로 구현하고, 정보 창이나 도움말에
  단축키 목록을 보여줍니다.
- **공통 단축키** (macOS는 ⌘, Windows와 Linux는 Ctrl):

  | 기능 | 키 |
  |---|---|
  | 열기 | ⌘O |
  | 설정 | ⌘, (설정 창, [settings.md](settings.md)) |
  | 창 닫기 | ⌘W |
  | 찾기 | ⌘F |
  | 새로 고침 | ⌘R / F5 |
  | 도움말 | F1 |
  | 대화상자 닫기 | Esc |

- **우클릭 메뉴**: `onSecondaryTapDown` + `showMenu`로 만듭니다. 메뉴
  항목에 단축키를 함께 표시합니다.
- **드래그 앤 드롭**: 파일을 다루는 앱은 창 전체를 드롭 영역으로
  받습니다(`desktop_drop`). 드래그 중에는 강조 테두리를 표시합니다.
- **macOS 메뉴 막대**: `PlatformMenuBar`로 앱 메뉴(정보, 설정, 종료)와
  주요 단축키를 등록합니다.

### 8. 설계 문서

- 각 앱에 `UI_UX.md`를 두고, 이 문서와 **다른 점만** 적습니다. 예: 앱
  고유의 화면 구조, 추가 단축키, 앱 전용 컴포넌트.
- 공통 규칙을 앱 문서에 다시 쓰지 않습니다.
