# 아이콘 규칙

앱 아이콘(런처·Dock·설치 프로그램)과 앱 안 UI 아이콘 두 가지를 다룹니다.

## 현재 상태

- 원본 이미지는 전부 Icons8 글리프입니다 (portside, allwinner, saturn,
  daylight). Icons8은 유료 플랜으로 쓰고 있습니다.
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
├── source_glyph.svg     # Icons8 "Sticker" 글리프 원본 (있으면 이것이 기준)
├── source_glyph.png     # 투명 배경 1024px — SVG에서 스크립트가 만든다
├── app_icon_1024.png    # 생성 결과: 모든 플랫폼의 기준 이미지
└── app_icon.png         # 앱 안에서 쓰는 256px 사본 (정보 창 등)
```

- 글리프는 Icons8 **Sticker** 스타일(흰 테두리 + 그림자)을 씁니다. 흰
  테두리 덕분에 그라데이션 판 위에서 16px까지 형태가 읽힙니다 (MacBroom).
- **SVG로 받습니다.** 한 번 받으면 모든 크기를 만들 수 있어 다운로드 수를
  아낍니다. SVG가 없으면 투명 배경 **1024px** PNG로 받습니다. macOS 판 위의
  글리프가 여백을 잘라낸 뒤에도 흐려지지 않으려면 512px로는 부족합니다.
- SVG는 macOS 렌더러([`render_svg.swift`](../common/tool/icon/render_svg.swift))로
  PNG를 만듭니다. ImageMagick 내장 렌더러는 Icons8 SVG의 외곽선을 빠뜨리고
  도형 위치를 틀리게 그리므로 쓰지 않습니다.
- 캐릭터·브랜드처럼 제3자 권리가 있는 그림은 쓰지 않습니다. Icons8
  라이선스는 Icons8의 권리만 허락합니다.

### 2. 한 스크립트로 모든 플랫폼 생성

[`common/tool/icon/generate_icons.py`](../common/tool/icon/generate_icons.py)를
앱의 `tool/icon/`에 복사해서 씁니다. allwinner(macOS, Windows, Linux)와
saturn(iOS, Android) 스크립트를 합친 것입니다. 앱에 있는 플랫폼 폴더만
처리합니다.

```bash
pip3 install pillow
python3 tool/icon/generate_icons.py   # source_glyph.svg → .png → 모든 플랫폼
```

스크립트가 만드는 것:

| 플랫폼 | 산출물 | 형태 |
|---|---|---|
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 16~1024 | 1024 캔버스 안 824px 둥근 사각형 판(반경 185, Apple 그리드)과 아래 그림자. 글리프는 440px(판의 약 53%) — 스티커 테두리 둘레에 그라데이션이 보여야 합니다 |
| Windows | `windows/runner/resources/app_icon.ico` (256/128/64/48/32/16) | 캔버스를 꽉 채운 판(모서리 12%) 위에 글리프가 캔버스의 80%. 작업 표시줄에서 macOS 비율의 글리프는 너무 작아 보이기 때문입니다 |
| Linux | `linux/runner/resources/app_icon.png` 512px. 릴리스 tarball에 이 파일이 들어갑니다 | Windows와 동일 |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 꽉 찬 사각형 판. **알파 채널 제거** (App Store 거부 방지) |
| Android | 레거시 mipmap + adaptive (`mipmap-anydpi-v26`) | 전경 = 글리프(안전 영역 66% 안), 배경 = 판 그라데이션 이미지 |

### 3. 판 색상

판은 **왼쪽 위 → 오른쪽 아래 대각선 그라데이션 `#7C6CFF → #E961FF`**
(보라 → 분홍)에 위쪽 약 절반을 덮는 흰색 11% 광택입니다. MacBroom 아이콘에서
가져왔습니다. 모든 앱이 같은 판을 쓰면 Dock이나 홈 화면에서 "한 제작자의
앱"으로 보입니다. 글리프로 앱을 구분하고, 판 색은 바꾸지 않습니다.

- 이전 규칙의 어두운 판(`#1F2A38 → #0A0E14`)과 saturn의 단색 `#142233`은
  다음 아이콘 갱신 때 이 판으로 바꿉니다.

### 4. 트레이 / 메뉴바 아이콘

- macOS는 단색 검정 + 투명 PNG를 `isTemplate: true`로 설정합니다 (MacBroom
  방식). 이렇게 하면 라이트·다크 메뉴바에서 OS가 알아서 색을 바꿉니다.
- 크기는 22pt 기준 @1x/@2x/@3x(22/44/66px)입니다. 지금 MacBroom의 144px
  단일 파일은 여기에 맞춰 교체합니다.
- Windows 트레이 아이콘은 `.ico` 16/32입니다.

## 앱 안 UI 아이콘 테마

두 가지가 섞여 있어서, 역할에 따라 나눠 씁니다.

| 선택지 | 쓰는 앱 | 장점 | 단점 |
|---|---|---|---|
| A. Icons8 "Windows 11 Color" SVG + `flutter_svg` | daylight, dove-zip | 컬러라 데스크톱 파일 관리자 느낌. 파일 형식 아이콘이 풍부함 | 에셋 관리 필요, 다크 모드에서 대비 확인 필요 |
| B. Material Symbols Rounded | portside, allwinner, saturn | 의존성 없음, 테마 색을 자동으로 따름 | 단색이라 앱마다 개성이 적음 |

규칙:
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
- Icons8은 유료 플랜이라 저작자 표시 의무가 없습니다 ([licensing.md](licensing.md)).
