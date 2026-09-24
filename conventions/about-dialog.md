# 정보 창 (About) 형식

## 현재 상태

| 앱 | 방식 | 버전 출처 | 빌드 번호 | 저작권 | 라이선스 | 오픈소스 고지 | 링크 |
|---|---|---|---|---|---|---|---|
| daylight | 직접 만든 `AlertDialog`, 기능 목록 포함 | package_info_plus | ✓ | ✓ | "License: MIT" | ✗ | GitHub 버튼 |
| dove-zip | daylight에서 이식 | package_info_plus | ✓ | ✗ | "License: MIT" | ✗ | GitHub 버튼 |
| allwinner | `AlertDialog`, 400px | 하드코딩 (틀림) | ✗ | ✓ | ✗ | ✗ | ✗ |
| portside | `AlertDialog`, 320px, Material 아이콘 | 하드코딩 | ✗ | ✗ | ✗ | ✗ | 텍스트만 |
| MacBroom | 없음 (macOS 기본 About만) | — | — | — | — | — | — |
| saturn (mobile) | 설정 화면 "단말 정보" 섹션 | package_info_plus | ✗ | ✗ | ✗ | ✗ | ✗ |

daylight와 dove-zip 형식이 가장 완성도가 높으므로 이를 기준으로 삼고,
빠진 항목을 채웁니다.

## 규칙

### 1. 진입 경로

| 플랫폼 | 진입 경로 |
|---|---|
| 데스크톱 (공통) | 메인 화면 AppBar 오른쪽 끝의 `info` 아이콘 버튼. 툴팁 "정보" / "About" |
| macOS 추가 | 앱 메뉴의 "About <표시 이름>" 항목이 **같은 대화상자**를 엽니다. `PlatformMenuBar`로 연결하거나, `MainMenu.xib`의 기본 About 항목을 채널로 연결합니다 |
| 메뉴바 전용 앱 | 트레이 메뉴에 "About <표시 이름>" 항목 |
| 모바일 | 설정 화면 맨 아래 "앱 정보" 섹션. 행을 누르면 같은 내용의 전체 화면 페이지 |

### 2. 내용과 배치 (위에서 아래로)

```
┌───────────────────────────────────────────┐
│ [앱 아이콘 48]  Dove Zip                   │  ← 실제 앱 아이콘 이미지 (Material 아이콘 X)
│                 버전 1.4.2 (빌드 37)       │  ← package_info_plus
│                                           │
│ 한 줄 소개 (tagline)                       │
│ 설명 2~3줄                                 │
│                                           │
│ ─────────────────────────────────────────  │
│ Copyright © 2026 Jongyun Ahn              │  ← identity.md 저작권 문자열
│ MIT License                                │
│                                           │
│ [오픈소스 라이선스]  [GitHub]      [닫기]   │
└───────────────────────────────────────────┘
```

| 항목 | 필수 | 규칙 |
|---|---|---|
| 앱 아이콘 | ✓ | `assets/icon/app_icon.png`를 48px로 표시합니다 |
| 표시 이름 | ✓ | 제목 스타일 |
| 버전 | ✓ | `버전 {version} (빌드 {buildNumber})` 형식으로, `PackageInfo.fromPlatform()`에서 읽습니다. 복사할 수 있도록 `SelectableText`로 둡니다 |
| 한 줄 소개와 설명 | ✓ | l10n 문자열 |
| 기능 목록 | 선택 | 넣는다면 6개 이하. 스크롤이 생기면 뺍니다 |
| 저작권 | ✓ | [identity.md](identity.md)의 문자열 그대로 |
| 라이선스 이름 | ✓ | 예: `MIT License` |
| 에셋 저작자 표시 | 조건부 | 저작자 표시 조건이 있는 에셋을 쓴 경우만. Icons8은 유료 플랜이라 넣지 않습니다 |
| 오픈소스 라이선스 버튼 | ✓ | `showLicensePage(applicationName:, applicationVersion:, applicationIcon:, applicationLegalese:)` |
| GitHub / 웹사이트 버튼 | 공개 저장소면 ✓ | `url_launcher` |
| 닫기 | ✓ | FilledButton, 오른쪽 끝 |

- 너비는 최대 440입니다. 내용이 넘치면 스크롤합니다.
- "Built with Flutter (Dart)" 같은 줄은 넣지 않습니다. 오픈소스 라이선스
  페이지가 그 역할을 합니다.
- 모든 문자열은 l10n(ko 기본 + en)으로 관리합니다. 앱에 l10n이 없으면
  한국어로 씁니다.

### 3. 공통 구현

[`common/lib/about/about_dialog.dart`](../common/lib/about/about_dialog.dart)를
각 앱의 `lib/about/`에 복사하고, 앱마다 다른 문구만 인자로 넘깁니다.
문자열 키는 [`common/l10n/`](../common/l10n/)의 ARB에서 가져와 앱 ARB에
합칩니다.

```dart
showAppAboutDialog(
  context,
  tagline: l10n.aboutTagline,
  description: l10n.aboutDescription,
  features: [l10n.aboutFeatureExtract, l10n.aboutFeatureCompress], // 선택
);
```

표시 이름, 저장소 URL, 저작권자, 라이선스 이름, 아이콘 경로는
[`lib/app_identity.dart`](../common/lib/app_identity.dart)의 상수에서
읽습니다. identity.md의 값을 앱 코드에 반영하는 곳은 이 파일 하나뿐입니다.
데스크톱 릴리스 워크플로는 이 파일의 `displayName`이 `AppInfo.xcconfig`의
`PRODUCT_NAME`과 같은지 검사합니다.

오픈소스 라이선스 화면에 글꼴 같은 비 pub 에셋을 더하는 코드는
[`common/lib/about/extra_licenses.dart`](../common/lib/about/extra_licenses.dart)에
있습니다 ([licensing.md](licensing.md) §2).

### 4. 테스트

정보 창이 열리고 버전 문자열이 표시되는지 위젯 테스트를 하나 둡니다.
dove-zip의 `home_screen_about_test.dart`가 그 예입니다.
