# 아이콘 규칙

앱 아이콘(런처·Dock·설치 프로그램)과 앱 안 UI 아이콘 두 가지를 다룹니다.

## 현재 상태

- 앱 아이콘은 **고양이 + 앱 소품 배지**입니다. 모든 앱이 같은 고양이를 쓰고,
  판 색과 소품으로 앱을 구분합니다. 13개 앱(portside, daylight-terminal,
  branch-dock, daylight-commander, dove-zip, flutty-dock, kamailio-sip-client,
  macbroom, notes2hub, rs485-pc-emulator, stevedore, webservice-central,
  allwinner-phoenix)이 PR로 옮겨 가는 중입니다.
- 소품 글리프가 없는 앱(janus-webrtc-client, tiki-taka, saturn-mobile-client,
  flutter_baresip, flutter_drag_out)은 아직 옮기지 않았습니다.
- 원본 이미지는 전부 Icons8입니다(고양이, 소품 글리프). Icons8은 유료 플랜으로 쓰고
  있습니다.
- UI 아이콘은 Material Icons(portside, allwinner, saturn)와 Icons8 "Windows
  11 Color" SVG(daylight, dove-zip)로 나뉩니다.

## 앱 아이콘

### 1. 원본 파일 (저장소에 커밋)

```
assets/icon/
├── source_glyph.svg     # 앱 소품 글리프 원본 (Icons8, 있으면)
├── source_glyph.png     # 앱 소품 글리프: 투명 배경 1024px
├── cat.json             # 고양이 모드 설정 (아래)
├── app_icon_1024.png    # 생성 결과: 모든 플랫폼의 기준 이미지
└── app_icon.png         # 앱 안에서 쓰는 256px 사본 (정보 창 등)
```

- **고양이 원본은 저장소에 두지 않습니다.** Icons8에서 유료로 받은
  `icons8-grinning-cat-1024.png`이고, 저장소가 공개라서 원본은 커밋하지 않습니다.
  스크립트가 경로를 인자로 받습니다. 생성된 아이콘 PNG에는 고양이가 들어갑니다.
- 소품은 앱을 나타내는 Icons8 글리프입니다. 앱의 `source_glyph.png`가 곧 소품이며
  고양이 모드에서는 이 파일이 아이콘 전체를 대신하지 않고 오른쪽 아래 배지가 됩니다.
- 소품은 **투명 배경 1024px PNG**로 받습니다(SVG면 더 좋습니다). 스티커형(흰 테두리 +
  그림자), 컬러, 흰색 단색 모두 쓸 수 있습니다.
- SVG는 macOS 렌더러([`render_svg.swift`](../common/tool/icon/render_svg.swift))로
  PNG를 만듭니다. ImageMagick 내장 렌더러는 Icons8 SVG의 외곽선을 빠뜨리고
  도형 위치를 틀리게 그리므로 쓰지 않습니다.
- 소품은 앱마다 달라야 합니다. 같은 소품(예: 터미널)을 쓰는 앱은 판 색으로만
  구분되고, 작은 크기에서는 그 구분이 약합니다.
- 캐릭터·브랜드처럼 제3자 권리가 있는 그림은 쓰지 않습니다. Icons8
  라이선스는 Icons8의 권리만 허락합니다. 앱 아이콘 용도 허용 여부는 구입한 플랜의
  라이선스로 확인합니다.

### 2. 한 스크립트로 모든 플랫폼 생성

[`common/tool/icon/generate_icons.py`](../common/tool/icon/generate_icons.py)를
앱의 `tool/icon/`에 복사해서 씁니다. 앱에 있는 플랫폼 폴더만 처리합니다.

```bash
pip3 install pillow
python3 tool/icon/generate_icons.py <고양이 이미지 경로>   # assets/icon/cat.json의 설정으로 생성
```

`assets/icon/cat.json`은 이 앱의 아이콘 설정입니다. 명령줄 옵션
(`--app-id`, `--hue`, `--prop-tile`)이 있으면 그쪽이 우선합니다.

```json
{
  "app_id": "stevedore",
  "hue": 172,
  "prop_tile": true
}
```

| 키 | 뜻 |
|---|---|
| `app_id` | 필수. 이 값의 SHA-256으로 판 hue를 정합니다 |
| `hue` | 선택. 0~360도. 해시 대신 hue를 직접 지정합니다 |
| `prop_tile` | 소품을 어두운 둥근 타일(흰 스티커 테두리) 위에 얹습니다. **모든 앱이 `true`** 입니다 |

스크립트가 만드는 것:

| 플랫폼 | 산출물 | 형태 |
|---|---|---|
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 16~1024 | 1024 캔버스 안 824px 둥근 사각형 판(반경 185, Apple 그리드)과 아래 그림자. 고양이+소품이 판의 약 80% |
| Windows | `windows/runner/resources/app_icon.ico` (256/128/64/48/40/32/24/20/16) | **판 없이 고양이+소품만**(투명 배경, 캔버스의 96%). 크기마다 따로 그리고 48px 이하는 가볍게 선명화합니다 — 아래 "Windows 예외" 참고 |
| Linux | `linux/runner/resources/app_icon.png` 512px. 릴리스 tarball에 이 파일이 들어갑니다 | 캔버스를 꽉 채운 판(모서리 12%) 위에 고양이+소품이 캔버스의 80% |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | 꽉 찬 사각형 판. **알파 채널 제거** (App Store 거부 방지) |
| Android | 레거시 mipmap + adaptive (`mipmap-anydpi-v26`) | 전경 = 고양이+소품(안전 영역 66% 안), 배경 = 판 그라데이션 이미지 |

#### 고양이와 소품의 배치

- 고양이는 왼쪽 위(캔버스의 68%, 중심에서 왼쪽 5%·위 6%), 소품 배지는 오른쪽
  아래(42%, 모서리에서 6% 안쪽)입니다. 소품이 고양이 입을 조금 가립니다.
- 고양이에는 아래쪽 그림자를 넣고, 소품 타일은 스티커 자체의 테두리를 씁니다.
- 어두운 타일(`#2A2D45`)은 소품을 판 색과 분리합니다. 흰색 단색 글리프는 이 타일이
  없으면 고양이 위에서 묻히고, 밝은 배경(Windows)에서는 보이지 않습니다. 스티커형
  소품도 타일 안에서 600px로 키워 같은 크기와 모양으로 보이게 합니다.
- Android adaptive는 소품 모서리가 안전 영역 안에 들어오도록 전경을 캔버스의
  46%로 줄입니다.

#### Windows 예외: 판 없이 고양이+소품만

작업 표시줄과 탐색기 목록에는 작은 아이콘이 나란히 놓입니다. 판을 씌우면 판
색만으로 앱을 구분해야 하는데, 고양이가 모든 앱에 같아서 판이 없으면 소품이
유일한 구분 요소입니다. macOS Dock은 아이콘이 크고 판 색이 보여 문제가 되지
않습니다. 그래서 Windows `.ico`만 판을 빼고 고양이와 소품 타일의 실루엣을 그대로
씁니다(이 판 규칙의 유일한 예외).

- 1024px 원본 하나를 줄이면 윤곽선이 뭉개집니다. 16~256px을 크기마다 따로
  그립니다.
- Windows는 125~150% 배율에서 20/24/40px을 요청합니다. 없으면 이웃 크기를
  늘리거나 줄여 흐려지므로 같이 넣습니다.
- 소품 타일이 어둡고 흰 테두리가 있어서, 어두운 작업 표시줄과 밝은 테마 모두에서
  윤곽이 보입니다.
- 16px에서는 소품이 색 덩어리로만 보입니다. 작은 크기용 단순화 고양이는 아직
  없습니다.

### 3. 판 색상

판 색이 앱을 구분하는 첫째 단서입니다. 같은 고양이가 앱마다 다른 색 판 위에
놓입니다.

- **hue는 앱 ID의 SHA-256에서 정합니다.** 같은 ID는 항상 같은 색이라 기본적으로는
  색을 따로 기록하지 않아도 됩니다.
- 채도·명도는 고정해 시리즈의 통일감을 유지합니다. 위는 밝고(채도 55%, 명도 95%)
  아래는 어두운(85%, 55%) 세로 그라데이션이고, 고양이 뒤에 옅은 원형 후광이
  있습니다.
- 고양이(주황·노랑)와 겹치는 hue 구간(약 10°~72°)은 제외합니다.
- **해시 hue가 다른 앱과 가까우면 `cat.json`의 `hue`로 직접 지정합니다.** 앱이
  13개를 넘으면 해시만으로는 비슷한 색이 나옵니다. 새 앱은 기존 앱의 hue와
  **20° 이상** 떨어지게 하고, 그렇지 않으면 hue를 고정합니다.

| 앱 | hue | 정하는 방식 |
|---|---|---|
| branch-dock | 78° | 해시 |
| notes2hub | 98° | 고정 |
| macbroom | 124° | 고정 |
| daylight-terminal | 148° | 고정 |
| stevedore | 172° | 고정 |
| kamailio-sip-client | 182° | 해시 |
| flutty-dock | 214° | 해시 |
| webservice-central | 220° | 해시 |
| portside | 244° | 해시 |
| dove-zip | 259° | 해시 |
| rs485-pc-emulator | 285° | 고정 |
| daylight-commander | 309° | 해시 |
| allwinner-phoenix | 336° | 해시 |

- 가까운 쌍이 남아 있습니다: kamailio-sip-client 182°·stevedore 172°,
  flutty-dock 214°·webservice-central 220°(6°).
- 고양이 모드로 옮기지 않은 앱은 예전 판(왼쪽 위 → 오른쪽 아래 대각선
  `#7C6CFF → #E961FF`, 위쪽 절반에 흰색 11% 광택)을 그대로 씁니다. 이 판은
  옵션 없이 `generate_icons.py`를 실행할 때 나옵니다.

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
