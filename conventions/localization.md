# 언어 설정과 현지화

## 현재 상태

| 앱 | 방식 | 기준 언어 | 설정 저장 | 전환 UI |
|---|---|---|---|---|
| daylight | gen-l10n (ko 188 / en 188 키) | ko | `app_locale` (prefs) | 앱 바 아이콘, 누를 때마다 순환 |
| dove-zip | gen-l10n (en 약 36키 누락) | ko | `locale` (prefs) | 앱 바 아이콘, 누를 때마다 순환 |
| allwinner | gen-l10n (ko 약 16키 누락) | **en** | 일반 파일 `…/AllwinnerFlasher/language` | 체크 표시가 있는 팝업 메뉴 |
| portside | 없음 (한국어 하드코딩 약 72줄) | — | — | — |
| saturn | 없음 (한국어 하드코딩 약 530줄) | — | — | — |
| MacBroom | 없음 (영어 하드코딩) | — | — | — |

- 세 앱 모두 "설정 안 함(null) = 시스템 언어 따름" 방식입니다.
- daylight 코드 주석에는 "지원하지 않는 언어는 영어로 대체"라고 적혀
  있지만, 이를 처리하는 `localeResolutionCallback`은 실제로 없습니다.

## 규칙

### 1. 처음부터 gen-l10n으로 만든다

- 한국어만 지원하는 앱이라도 **첫 커밋부터** ARB로 문자열을 관리합니다.
  나중에 하드코딩된 문자열 수백 줄을 옮기는 비용(saturn 약 530줄)이 훨씬
  큽니다.
- 지원 언어는 **한국어(ko)와 영어(en)** 이고, 둘 다 필수입니다.

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb
output-class: AppLocalizations
nullable-getter: false
untranslated-messages-file: build/untranslated.json
```

### 2. 기준 언어는 한국어, 누락 번역은 CI에서 막는다

- 기준(template) ARB는 `app_ko.arb`입니다.
- `app_en.arb`는 **모든 키**를 가져야 합니다. CI에서
  `flutter gen-l10n` 후 `build/untranslated.json`이 비어 있지 않으면
  실패시킵니다. 지금 dove(en 약 36키)와 allwinner(ko 약 16키)에 빠진
  번역이 있습니다.
- 키 이름은 lowerCamelCase이고 화면 이름을 접두어로 붙입니다. 예:
  `aboutTagline`, `homeEmptyTitle`, `commonCancel`.
- 앱 표시 이름은 번역하지 않습니다. ARB가 아니라 `app_identity.dart`
  상수에 둡니다 (allwinner 방식).

### 3. 언어 선택 방식

| 설정 값 | 동작 |
|---|---|
| 시스템 (기본) | OS 언어가 ko이면 한국어, **그 밖의 모든 언어는 영어** |
| 한국어 | ko 고정 |
| English | en 고정 |

"그 밖의 언어는 영어" 규칙은 반드시 `localeResolutionCallback`으로 구현합니다.
이 콜백이 없으면 Flutter는 지원 목록의 첫 번째 언어(ko)로 대체합니다.

```dart
localeResolutionCallback: (device, supported) =>
    device?.languageCode == 'ko' ? const Locale('ko') : const Locale('en'),
```

### 4. 전환 UI

- **데스크톱**: 앱 바의 언어 아이콘을 누르면 체크 표시가 있는 팝업 메뉴가
  열립니다 (allwinner 방식).
  - 항목은 `시스템 설정 따르기 / System`, `한국어`, `English`입니다.
  - 언어 이름은 **그 언어로** 씁니다. 잘못 선택해서 읽을 수 없는 언어가
    되어도 되돌아올 수 있게 하기 위해서입니다.
  - 순환 버튼(daylight, dove)은 현재 상태와 다음 상태가 보이지 않으므로
    쓰지 않습니다.
- **모바일**: 설정 화면의 `SegmentedButton`을 씁니다 (saturn의 테마 선택
  방식).
- 바꾸면 앱을 다시 시작하지 않고 즉시 적용합니다.

### 5. 설정 저장 키 (언어·테마 공통)

`shared_preferences` 키를 앱마다 다르게 짓지 않습니다.

| 키 | 값 | 없을 때 |
|---|---|---|
| `app_locale` | `ko` / `en` | 시스템 |
| `theme_mode` | `ThemeMode.name` (`system` / `light` / `dark`) | 시스템 |
| `text_scale` | `double` | 1.0 |

앱 고유 설정에는 `<기능>_<이름>` 형식을 씁니다 (예: `terminal_font_family`).
`user.theme_mode`처럼 점이 들어간 접두어는 쓰지 않습니다.

### 6. 날짜, 숫자, 크기 표기

- `intl` 패키지의 `DateFormat`과 `NumberFormat`에 **현재 로케일**을
  넘깁니다.
  - saturn의 `DateFormat('M월 d일 HH:mm')`처럼 형식 문자열에 한국어를
    넣지 않습니다.
  - 대신 `DateFormat.MMMd(locale).add_Hm()`처럼 로케일별 스켈레톤을 씁니다.
- 파일 크기는 공통 함수 하나로 표시합니다. 단위는 KB/MB/GB이고 1024
  기준이며, 소수점 첫째 자리까지 씁니다.
- `intl` 버전은 Flutter SDK가 고정한 버전을 따르므로 `intl: any`로
  둡니다.

### 7. 문장 스타일

- 한국어 UI 문구는 "~합니다" 대신 **간결한 명사형이나 해요체**를 씁니다.
  - 버튼: `열기`, `압축 풀기`
  - 안내: `파일을 끌어다 놓으세요`
- 영어 UI 문구는 버튼과 메뉴는 Title Case(`Open File`), 문장은 Sentence
  case입니다.
- 오류 메시지는 무엇이 잘못됐는지와 사용자가 할 수 있는 일을 함께
  적습니다.
