# 다크 / 라이트 테마 전략

## 현재 상태

| 앱 | 지원 모드 | 기본값 | 저장 키 | 전환 UI |
|---|---|---|---|---|
| daylight | 시스템 / 라이트 / 다크 | 시스템 | `theme_mode` | 앱 바 아이콘, 누를 때마다 순환 (Icons8 SVG) |
| dove-zip | 시스템 / 라이트 / 다크 | 시스템 | `theme_mode` | 앱 바 아이콘, 누를 때마다 순환 (Material) |
| saturn | 시스템 / 라이트 / 다크 | **다크** | `user.theme_mode` | 설정 화면 `SegmentedButton` |
| allwinner | 시스템만 (라이트와 다크 둘 다 구현) | 시스템 | — | 없음 |
| portside | 다크만 | — | — | 없음 (`theme` 키는 터미널 색 구성표) |
| MacBroom | 다크만 (`macos_ui`) | — | — | 없음 |

색은 모든 Material 앱이 손으로 만든 `ColorScheme.dark()` / `.light()`를
쓰고, 값은 같습니다 (Saturn 팔레트). `ColorScheme.fromSeed`를 쓰는 앱은
없습니다.

## 규칙

### 1. 라이트와 다크 모두 지원, 기본값은 시스템

- 모든 앱은 **시스템 / 라이트 / 다크** 세 가지를 지원합니다. 설정하지
  않았으면 시스템을 따릅니다.
- 두 테마는 **동등하게** 다룹니다. 한쪽을 기준으로 만들고 다른 쪽을
  나중에 맞추지 않습니다. 이는 daylight `UI_UX.md`의 원칙입니다.
  `AppTheme._base(Brightness)` 하나에서 두 테마를 만듭니다.
- 예외로 기본값을 다크로 둘 수 있는 경우:
  - 사용 환경이 주로 어두운 곳인 앱(saturn: 월패드 옆 야간 사용)
  - 터미널 성격의 앱(portside)
  - 이때도 라이트 테마는 구현합니다. 다크 전용으로 남기려면 앱
    `UI_UX.md`에 이유를 적습니다.
- portside의 터미널 색 구성표처럼 **콘텐츠 영역의 색 테마**는 앱 테마와
  별개입니다. 설정 키 이름도 `terminal_palette`처럼 분리합니다.

### 2. 색 토큰 (Saturn 팔레트)

`ColorScheme.fromSeed`를 쓰지 않고, 아래 값으로 `ColorScheme`을 직접
만듭니다.

| 토큰 | 다크 | 라이트 | 용도 |
|---|---|---|---|
| `bg` | `#0A0E14` | `#F4F6FA` | Scaffold 배경 |
| `surface` | `#151D27` | `#FFFFFF` | 카드, 패널 |
| `surfaceHi` | `#1D2733` | `#E3E8EF` | 팝업, 메뉴, 스낵바. 배경과 구분되도록 테두리를 함께 씁니다 |
| `stroke` | `#FFFFFF` 10% | `#000000` 8% | 카드 테두리, 구분선 |
| `strokeStrong` | `#FFFFFF` 20% | `#000000` 14% | 팝업 테두리, 입력칸 |
| `primary` | `#4C9DFF` | `#2C6BE0` (`primaryDeep`) | 주 행동, 포커스, 링크 |
| `accent` (`secondary`) | `#7C5CFF` | `#7C5CFF` | 보조 강조 |
| `textHi` | `#F1F5F9` | `#101828` | 본문 |
| `textMid` | `#A9B4C4` | `#5B6676` | 보조 텍스트 |
| `textLow` | `#6B7787` | `#8A94A6` | 비활성, 힌트 |
| `success` | `#34D399` | `#34D399` | 완료, 연결됨 |
| `warning` | `#FFB020` | `#FFB020` | 주의 |
| `error` (`danger`) | `#FF5A5F` | `#FF5A5F` | 오류, 위험 버튼 |

값은 daylight `app_theme.dart`(origin/main)에서 가져왔습니다.

- 의미 색(success, warning, error)은 아이콘·점·배경에 두 테마 공통으로
  씁니다. **흰 배경 위 글자색**으로는 대비가 부족하므로(특히 `warning`
  `#FFB020`) 라이트 테마에서는 글자용 변형을 씁니다: `successTextLight`
  `#047857`, `warningTextLight` `#B45309`, `dangerTextLight` `#C81E24`
  (라이트 테마의 `colorScheme.error`).
- 기준 구현: [`common/lib/theme/app_theme.dart`](../common/lib/theme/app_theme.dart).
  `ColorScheme`의 모든 슬롯(`onSurfaceVariant`, `outline`,
  `surfaceContainerHighest` 등)을 채웁니다. 비워 두면 Material 기본값이
  들어가 팔레트와 어긋납니다.

- 위젯에서 `Color(0x...)`를 직접 쓰지 않습니다. 반드시
  `Theme.of(context).colorScheme`이나 `AppColors.of(context)`를 거칩니다.
- 앱 고유의 의미 색(daylight의 파일 종류 색, saturn의 기기별 강조색)은
  **라이트와 다크 한 쌍**으로 정의합니다.

### 3. 전환 UI

[localization.md](localization.md)의 언어 전환과 **같은 방식**으로 만듭니다.

- 기준 구현: [`common/lib/settings/`](../common/lib/settings/) —
  `AppSettings`(저장·이전·언어 해석), `ThemeMenuButton`,
  `LanguageMenuButton`, 모바일용 `*SegmentedButton`.
- **데스크톱**: 앱 바 아이콘을 누르면 체크 표시가 있는 팝업 메뉴가 열리고,
  항목은 `시스템 설정 따르기`, `라이트`, `다크`입니다.
  - 아이콘은 현재 모드를 보여줍니다: `brightness_auto` / `light_mode` /
    `dark_mode` (Material Symbols Rounded).
- **모바일**: 설정 화면의 `SegmentedButton`을 씁니다 (saturn 방식).
- 저장 키는 `theme_mode`이고, 값은 `ThemeMode.name`입니다.
- 앱 바 오른쪽 끝의 버튼 순서는 `… | 테마 | 언어 | 정보`입니다.

### 4. 창 테두리와 시스템 UI

- **macOS / Windows 창 제목 표시줄**: 앱에서 다크를 골라도 OS가 라이트면
  제목 표시줄은 밝게 남습니다. 테마가 바뀔 때마다
  `windowManager.setBrightness(brightness)`를 호출해서 맞춥니다.
- **모바일 상태 표시줄**: 테마 밝기에 따라 `SystemUiOverlayStyle`을
  설정합니다 (saturn 방식).
- **macOS 메뉴바 아이콘**: `isTemplate: true`로 OS가 처리하게 둡니다
  ([icons.md](icons.md)).

### 5. 아이콘과 이미지

- Material 아이콘은 테마 색을 자동으로 따릅니다.
- **Icons8 컬러 SVG**는 테마를 따르지 않습니다. 새로 넣을 때 라이트와
  다크 배경 **둘 다에서** 대비를 확인합니다. 한쪽에서 안 보이면 다크용
  변형(`*-dark.svg`)을 두고 `ToolIcon`이 밝기에 따라 고르게 합니다.
- 앱 아이콘의 판 색은 테마와 관계없이 고정입니다 ([icons.md](icons.md)).

### 6. 테스트

- 주요 화면의 골든 테스트나 스크린샷은 **라이트와 다크 두 벌**로
  만듭니다.
- README 스크린샷도 두 테마를 모두 싣거나, 최소한 기본 모드(시스템)에서
  찍은 것임을 밝힙니다.
