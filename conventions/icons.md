# 아이콘 규칙

앱 아이콘(런처·Dock·설치 프로그램)과 앱 안 UI 아이콘 두 가지를 다룹니다.

## 현재 상태

- 원본 이미지는 전부 Icons8 글리프입니다 (portside, allwinner, saturn,
  daylight). 하지만 저작자 표시는 allwinner만 하고 있습니다.
- 아이콘 생성 방법이 세 가지로 나뉩니다.
  - `flutter_launcher_icons`: portside
  - ImageMagick + Pillow 스크립트: allwinner
  - Python 스크립트: saturn
  - 나머지 앱은 손으로 넣었습니다.
- Linux 아이콘이 있는 앱은 allwinner뿐이고, Windows `.ico`에 256px가
  없는 앱도 있습니다.
- UI 아이콘은 Material Icons(portside, allwinner, saturn)와 Icons8 "Windows
  11 Color" SVG(daylight, dove-zip)로 나뉩니다.

## 앱 아이콘

### 1. 원본 파일 (저장소에 커밋)

```
assets/icon/
├── source_glyph.png     # 투명 배경 글리프, 최소 512px (Icons8 등에서 받은 원본)
├── app_icon_1024.png    # 생성 결과: 모든 플랫폼의 기준 이미지
└── app_icon.png         # 앱 안에서 쓰는 256px 사본 (정보 창 등)
```

### 2. 한 스크립트로 모든 플랫폼 생성

`tool/icon/generate_icons.py` 하나로 만듭니다. allwinner와 saturn
스크립트를 합쳐서 템플릿으로 옮길 예정입니다 (🟡 TODO). 스크립트가 할 일:

| 플랫폼 | 산출물 | 형태 |
|---|---|---|
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 16~1024 | 1024 캔버스 안 824px 둥근 사각형 판(반경 185, Apple 그리드). 글리프는 판의 약 73% |
| Windows | `windows/runner/resources/app_icon.ico` (256/128/64/48/32/16) | 판 없이 글리프가 캔버스의 92% |
| Linux | `linux/runner/resources/app_icon.png` 256px (+ 패키지용 사본) | Windows와 동일 |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 꽉 찬 사각형 판. **알파 채널 제거** (App Store 거부 방지) |
| Android | 레거시 mipmap + adaptive (`mipmap-anydpi-v26`) | 전경 = 글리프(안전 영역 66% 안), 배경 = 색상 리소스 |

### 3. 판 색상

🟡 **결정 필요** — 지금 쓰는 판 색은 비슷하지만 서로 다릅니다.
- allwinner: 그라데이션 `#1F2A38 → #0A0E14`
- saturn: 단색 `#142233`
- saturn 스크립트 docstring: `#0A0E14` (실제 코드와도 다름)

제안: 기본 판은 **그라데이션 `#1F2A38 → #0A0E14`** 로 하고, 앱별로 색을
바꿀 때는 스크립트 인자로 넘깁니다. 모든 앱이 같은 판을 쓰면 Dock이나 홈
화면에서 "한 제작자의 앱"으로 보입니다.

### 4. 트레이 / 메뉴바 아이콘

- macOS는 단색 검정 + 투명 PNG를 `isTemplate: true`로 설정합니다 (MacBroom
  방식). 이렇게 하면 라이트·다크 메뉴바에서 OS가 알아서 색을 바꿉니다.
- 크기는 22pt 기준 @1x/@2x/@3x(22/44/66px)입니다. 지금 MacBroom의 144px
  단일 파일은 여기에 맞춰 교체합니다.
- Windows 트레이 아이콘은 `.ico` 16/32입니다.

## 앱 안 UI 아이콘 테마

🟡 **결정 필요** — 두 가지가 섞여 있습니다.

| 선택지 | 쓰는 앱 | 장점 | 단점 |
|---|---|---|---|
| A. Icons8 "Windows 11 Color" SVG + `flutter_svg` | daylight, dove-zip | 컬러라 데스크톱 파일 관리자 느낌. 파일 형식 아이콘이 풍부함 | 에셋 관리 필요, 저작자 표시 필요, 다크 모드에서 대비 확인 필요 |
| B. Material Symbols Rounded | portside, allwinner, saturn | 의존성 없음, 테마 색을 자동으로 따름 | 단색이라 앱마다 개성이 적음 |

제안은 **A와 B를 역할로 나누는 것**입니다.
- **B** (Material Symbols Rounded): 툴바·버튼·메뉴 같은 UI 조작 아이콘.
  테마 색을 따라야 다크 모드가 자연스럽습니다.
- **A** (Icons8 Windows 11 Color): 파일 형식, 폴더, 기기처럼 **대상 자체를
  나타내는 아이콘**. daylight와 dove-zip이 실제로 이렇게 쓰고 있습니다.

A를 쓸 때 규칙:
- 경로는 `assets/icons/<분류>/icons8-<이름>-<크기>.svg`입니다 (다운로드
  원본 이름 유지).
- `ToolIcon` 같은 공통 위젯 하나로만 그립니다. daylight의
  `ToolIcon('icons8-information.svg')`가 그 예입니다.
- 쓰지 않는 에셋은 저장소에 두지 않습니다. portside의
  `assets/icons/icons8-*-500.png` 13개는 참조되는 곳이 없습니다.
- 저작자 표시를 합니다 ([licensing.md](licensing.md)).
