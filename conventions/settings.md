# 설정 창

데스크톱 앱의 **화면 관련 사용자 설정**(테마, 색 구성, 글자 크기, 언어)을 한곳에 모으는 방식입니다.
기준 구현은 daylight-commander(`lib/settings/settings_dialog.dart`)이고, 창 모양은
daylight-workbench의 설정 창을 따랐습니다.

> **가능하면** 적용합니다. 설정할 것이 거의 없는 앱, 모바일 앱(설정 *화면*을 따로 둔 saturn 방식),
> 앱 바 공간이 넉넉하고 팝업 메뉴가 더 나은 앱은 예외로 두고, 앱 `UI_UX.md`에 이유를 적습니다.
> 이미 [theming.md](theming.md)·[localization.md](localization.md)·[fonts.md](fonts.md)의 앱 바
> 팝업 메뉴를 쓰는 앱은 다음에 정비할 때 이 문서의 방식으로 **가능하면** 옮깁니다.

## 정의

| 설정 | 무엇 | 값 | 저장 키 | 없을 때 |
|---|---|---|---|---|
| 테마 | 밝기 | `system` / `light` / `dark` (`ThemeMode.name`) | `theme_mode` | 시스템 |
| 색 구성(color theme) | 주색 계열 | `saturn` / `teal` / `amber` / `rose` / `slate` / `highContrast` (`ColorPalette.name`) | `theme_palette` | `saturn` |
| 글자 크기 | 전체 글자 배율 | 0.9 작게 / 1.0 보통 / 1.15 크게 | `text_scale` | 1.0 |
| 언어 | UI 언어 | `ko` / `en` | `app_locale` | 시스템 |

- 테마와 색 구성은 **서로 독립**입니다. 밝기(라이트/다크)를 고른 뒤 그 위에 색 구성을 얹습니다.
- 바꾸면 앱을 다시 시작하지 않고 즉시 적용하고, 바로 저장합니다. 확인·적용 버튼은 두지 않습니다.
- 예전 키를 쓰던 앱(daylight-commander의 `font_scale`)은 `AppSettings.load(legacyKeys: …)`로 한 번
  옮겨서 사용자 설정이 사라지지 않게 합니다.

## 앱 바

- 설정 아이콘(Icons8 `icons8-settings.svg`, `ToolIcon`)을 **정보 아이콘 바로 왼쪽**에 둡니다.
  앱 바 오른쪽 끝은 `… | 설정 | 정보`입니다.
- 이전의 `글자 크기 | 테마 | 언어` 팝업 버튼은 **가능하면** 없애고 설정 창으로 옮깁니다.
  (macOS 메뉴 막대에 "설정…"(⌘,)이 있으면 같은 창을 엽니다 — [ui-ux.md](ui-ux.md).)

## 설정 창 구성

`AlertDialog` 안에 왼쪽 구역 목록 + 세로 구분선 + 오른쪽 내용을 둡니다 (너비 약 640, 높이 약 380).

| 구역 | 내용 | 위젯 |
|---|---|---|
| 화면 | 테마 | `SegmentedButton<ThemeMode>` — 시스템·라이트·다크, 각각 아이콘 포함 |
| | 색 구성 | `ChoiceChip`을 `Wrap`으로 — 색마다 주색 원(`primaryFor(brightness)`)을 앞에 보임. 고대비는 원 대신 대비 아이콘 |
| | 글자 크기 | `SegmentedButton<double>` — 작게·보통·크게 |
| 언어 | 언어 | `SegmentedButton<String>` — 시스템·한국어·English (언어 이름은 그 언어로) |

- 구역이 늘면 왼쪽 목록에 추가합니다 (workbench는 편집기·터미널 등 앱 고유 구역을 더 둠).
  앱 고유 설정은 [localization.md](localization.md) §5의 `<기능>_<이름>` 키를 씁니다.
- 선택한 구역은 배경을 채우지 않고 **왼쪽에 굵은 선**(3px, `primary`)으로 표시합니다.
  배경을 채우면 고대비에서 글자와 겹칩니다. 선택 안 된 줄도 같은 폭을 비워 글자가 밀리지 않게 합니다.
- 소제목은 `textTheme.titleSmall` 굵게. 닫기 버튼 하나만 둡니다.
- 문구는 ARB에 둡니다: `settingsTooltip`, `settingsTitle`, `settingsSection*`, `settingsBrightness`,
  `settingsPalette`, `settingsPalette{Saturn,Teal,Amber,Rose,Slate,HighContrast}`, `settingsFontSize`,
  `settingsLanguage`. 테마·글자 크기 선택지 문구(`themeSystem/Light/Dark`, `fontScaleSmall/Normal/Large`)는
  기존 키를 그대로 씁니다.

## 구현

### 상태

- 테마·색 구성·언어는 `AppSettings`(`ChangeNotifier`, `lib/settings/app_settings.dart`)가 들고 있고
  `AppSettingsScope`로 트리에 내립니다. 색 구성은 `palette` / `setPalette()`가 추가됩니다.
- 글자 크기는 앱이 쓰는 상태 관리를 따릅니다. Riverpod 앱이면 `fontScaleProvider`(`StateNotifier<double>`)를
  그대로 두고, 설정 창의 글자 크기 위젯만 `ConsumerWidget`으로 만듭니다.
- `MaterialApp`은 `ListenableBuilder(listenable: settings)` 안에서 만들어 설정이 바뀌면 다시 그립니다.
  ```dart
  theme: AppTheme.light(settings.palette),
  darkTheme: AppTheme.dark(settings.palette),
  themeMode: settings.themeMode,
  ```
  글자 크기는 `MediaQuery.textScaler`에 적용합니다 ([fonts.md](fonts.md) §6).

### 색 구성 (`ColorPalette`)

| 이름 | 다크 주색 | 라이트 주색 |
|---|---|---|
| `saturn` (기본) | `#4C9DFF` | `#2C6BE0` |
| `teal` | `#2DD4BF` | `#0F766E` |
| `amber` | `#FBBF24` | `#B45309` |
| `rose` | `#FB7185` | `#BE123C` |
| `slate` | `#94A3B8` | `#475569` |
| `highContrast` | `#FFD60A` | `#0000CC` |

- `saturn`은 [theming.md](theming.md) §2의 기본 팔레트 그대로입니다.
- `saturn`·`highContrast`를 뺀 나머지는 **주색(`primary`, `onPrimary`)만** 바꿉니다. 배경·표면·글자·
  의미 색은 그대로입니다. 다크는 `onPrimary`를 `bg`로, 라이트는 흰색으로 둡니다.
- `highContrast`는 주색만이 아니라 배경·글자·테두리를 순흑/순백 최대 대비로 바꾸는 **별도 `ColorScheme`**
  (`outline`·`onSurface`는 흑/백, `onSurfaceVariant`는 `#BFBFBF`/`#404040`, `surfaceContainerHighest`는
  `#262626`/`#E0E0E0`)이고, 반투명 테두리(`stroke`)도 꽉 찬 `outline` 색으로 바꿉니다.
- 앱 고유 의미 색(파일 종류 색 등)은 색 구성과 무관하게 고정입니다.

### 색을 테마에서 읽기 — 가장 중요한 규칙

색 구성이 화면 **전체**에 퍼지려면 위젯이 색을 테마에서 읽어야 합니다. `AppColors.primary` /
`AppColors.surface` / `AppColors.stroke` 같은 **상수를 위젯에서 직접 쓰면** 색 구성을 바꿔도 그 부분만
그대로 남습니다 (daylight-commander에서 디렉토리 트리·패널 테두리·강조색이 그랬습니다).

| 쓰는 곳 | 읽을 곳 |
|---|---|
| 강조·선택·커서·포커스 | `Theme.of(context).colorScheme.primary` |
| 카드·패널·트리 배경 | `colorScheme.surface` |
| 팝업·배너 배경 | `colorScheme.surfaceContainerHighest` |
| 본문 글자 | `colorScheme.onSurface` |
| 테두리·분할선 | `Theme.of(context).dividerColor` |

이를 위해 `ThemeData`에서 다음을 채웁니다 (비워 두면 Material 기본값이 들어가 팔레트와 어긋납니다).

- `ColorScheme`: `surfaceContainerHighest`에 `surfaceHi`, 고대비는 위 표의 슬롯 전부.
- `ThemeData.dividerColor = stroke` — `dividerTheme.color`만 지정하면 `Theme.of(context).dividerColor`를
  읽는 분할선(예: 드래그로 너비를 바꾸는 트리/패널 경계)은 기본색(흰색에 가까움)으로 남습니다.
- `popupMenuTheme`·`dividerTheme`의 테두리도 같은 `stroke` / `strokeStrong` 값을 씁니다.

색상 투명도만 밝기에 따라 다른 경우(`isDark ? 0.16 : 0.10`)는 `colorScheme.primary.withValues(alpha: …)`로
쓰고 알파만 분기합니다.

### 테스트

- 설정 창을 `Scaffold(body: SettingsDialog())`로 띄워 각 선택지를 눌러 값이 바뀌고(`AppSettings`,
  `fontScaleProvider`) `shared_preferences`에 저장되는지 확인합니다.
- 저장된 `theme_palette`를 읽는지, `AppTheme.light/dark(palette)`의 `primary`가 해당 색인지,
  고대비의 `surface`가 순흑/순백인지 확인합니다.
- 기존 키(`theme_mode`, `app_locale`)를 그대로 읽는지 확인합니다.
