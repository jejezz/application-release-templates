# 글꼴 전략

## 현재 상태

- Material 앱 5개가 모두 **SeoulNamsan**(서울남산체) 300/400/700/800을
  같은 `pubspec.yaml` 블록으로 번들합니다.
  - TTF 한 개가 약 4 MB라서, 글꼴만으로 **앱마다 약 16 MB**를 차지합니다.
- 기본 글꼴 지정은 대부분 `ThemeData(fontFamily: 'SeoulNamsan')`입니다.
  - portside만 모든 텍스트 스타일을 `w300`, `fontSize - 1`로 강제합니다.
- 고정폭 글꼴 지정이 앱마다 다릅니다.
  - daylight, dove: `'monospace'`
  - allwinner: `'Menlo'`
  - portside: 사용자가 고르는 목록
- `fontFamilyFallback`을 둔 앱은 없습니다. SeoulNamsan에 없는 글자(일부
  한자, 기호, 다른 언어)는 OS가 임의로 대체합니다.
- 글꼴 라이선스 파일을 넣은 앱이 없습니다.

## 규칙

### 1. 기본 글꼴: SeoulNamsan

- UI 전체에 SeoulNamsan을 씁니다. 한국어와 영어 모두 이 글꼴로 표시합니다.
- 번들하는 굵기는 **400 / 700 / 800 세 가지**입니다.
  - 300(Light)은 작은 크기에서 가독성이 떨어지므로 뺍니다. 그만큼 약
    4 MB가 줄어듭니다.
  - portside처럼 전체 굵기를 강제로 낮추는 것은 금지합니다.
- 글꼴 파일 위치와 선언은 아래로 통일합니다.
  ```yaml
  flutter:
    fonts:
      - family: SeoulNamsan
        fonts:
          - { asset: assets/fonts/seoul_namsan_regular.ttf, weight: 400 }
          - { asset: assets/fonts/seoul_namsan_bold.ttf, weight: 700 }
          - { asset: assets/fonts/seoul_namsan_extra_bold.ttf, weight: 800 }
  ```
- 🟡 TODO: 용량을 더 줄이려면 KS X 1001 한글 2,350자 + 라틴 문자로
  서브셋한 TTF를 공통 패키지(`zoomon_ui`)에 한 번만 두는 방법을
  검토합니다. 파일당 1 MB 이하가 목표입니다.

### 2. 대체 글꼴 (fallback)

SeoulNamsan에 없는 글자는 OS 한글 글꼴로 넘깁니다. 이렇게 하면 사용자가
만든 파일 이름이나 외부 데이터에 어떤 문자가 와도 두부(□)가 나오지
않습니다.

```dart
const kFontFallback = [
  'Apple SD Gothic Neo', // macOS, iOS
  'Malgun Gothic',       // Windows
  'Noto Sans CJK KR',    // Linux, Android
  'Noto Sans KR',
];
ThemeData(fontFamily: 'SeoulNamsan', fontFamilyFallback: kFontFallback);
```

### 3. 사용자 콘텐츠는 시스템 글꼴 사용

파일 이름, 경로, 사용자가 입력한 긴 텍스트 등 **앱이 통제하지 않는
문자열**은 시스템 UI 글꼴로 표시합니다. 이는 daylight `UI_UX.md` §5의
원칙을 공통 규칙으로 올린 것입니다. `fontFamily`를 지정하지 않고
fallback 목록만 준 `TextStyle`을 쓰면 됩니다.

### 4. 고정폭 글꼴

`'monospace'` 같은 일반 이름은 Flutter 데스크톱에서 제대로 해석되지
않으므로, 플랫폼별 이름을 목록으로 줍니다.

```dart
const kMonoFamily = 'Menlo';
const kMonoFallback = ['SF Mono', 'Consolas', 'Cascadia Mono',
    'DejaVu Sans Mono', 'Noto Sans Mono', 'Courier New'];
```

- 쓰는 곳: 로그, 16진수 덤프, 터미널, 코드, 체크섬.
- 표 안의 숫자는 고정폭 글꼴 대신
  `fontFeatures: [FontFeature.tabularFigures()]`로 자릿수를 맞춥니다
  (MacBroom 방식).
- 터미널 앱(portside)은 사용자가 글꼴을 고르게 할 수 있지만, 기본값은 위
  목록을 따릅니다.

### 5. 크기

글꼴 크기 체계는 [ui-ux.md](ui-ux.md)의 밀도 표를 따릅니다.
`Theme.of(context).textTheme`의 스타일을 쓰고, 위젯 안에 숫자를 직접 적지
않습니다.

### 6. 글자 크기 조절 (선택)

daylight의 글자 크기 조절(1.0 / 1.15 / 0.9)은 **선택 사항**입니다.
넣는다면 다음을 지킵니다.
- 구현은 `MediaQuery.textScaler`로 합니다.
- 설정 키는 `text_scale`입니다 ([localization.md](localization.md)의 설정
  키 규칙).

### 7. 라이선스

SeoulNamsan의 라이선스 원문을 `assets/licenses/seoul-namsan.txt`에 두고
`LicenseRegistry`에 등록합니다 ([licensing.md](licensing.md)).
