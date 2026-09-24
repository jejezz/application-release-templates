# OS별 패키징 규칙

## 현재 상태: 파일 이름이 앱마다, OS마다 다름

| 앱 | macOS | Windows | Linux |
|---|---|---|---|
| portside | `Portside-v0.1.8.dmg` | `PortsideSetup-0.1.8.exe` | `Portside-v0.1.8-linux-x64.tar.gz` |
| daylight | `DaylightCommander-macos.dmg` (버전 없음) | `DaylightCommander-Setup.exe` | `DaylightCommander-linux.tar.gz` |
| allwinner | `Allwinner Flasher-v1.1.2.dmg` (공백) | `AllwinnerFlasherSetup-1.1.2.exe` | `aw_flasher-v1.1.2-linux-x64.tar.gz` |
| dove-zip | `DoveZip-v0.1.1.dmg` | `DoveZipSetup-0.1.1.exe` | `dove_zip-v0.1.1-linux-x64.tar.gz` |
| MacBroom | `MacBroom-1.0.1.dmg` + `.zip` | — | — |

`v`가 붙는지, 이름 형식(PascalCase / snake_case / 공백), OS·아키텍처 표기가
모두 섞여 있습니다.

## 규칙

### 1. 산출물 파일 이름

```
<FileName>-<버전>-<os>-<arch>[-setup].<ext>
```

- `<FileName>`은 [identity.md](identity.md)의 파일 이름(PascalCase, 공백
  없음)입니다.
- `<버전>`에는 `v`를 붙이지 않습니다 (예: `1.4.2`, `1.5.0-rc.1`).
- `<os>`는 `macos`, `windows`, `linux`, `android`, `ios` 중 하나입니다.
- `<arch>`는 `universal`(Flutter macOS 기본), `arm64`, `x64` 중 하나입니다.

| OS | 파일 | 예 |
|---|---|---|
| macOS | DMG | `DoveZip-1.4.2-macos-universal.dmg` |
| Windows | Inno Setup 설치 프로그램 | `DoveZip-1.4.2-windows-x64-setup.exe` |
| Linux | tarball | `DoveZip-1.4.2-linux-x64.tar.gz` |
| 모두 | 체크섬 | `SHA256SUMS.txt` |

Rust 등 네이티브 코드 때문에 한 아키텍처만 빌드되면(allwinner는 arm64만),
그 아키텍처를 적습니다.

### 2. macOS

- 형식은 DMG이고, `create-dmg`로 Applications 링크가 있는 창을 만듭니다.
  창 크기와 배치는 템플릿 값(500×300, 아이콘 100, 링크 380,120)을
  그대로 씁니다.
- 서명은 Developer ID Application + hardened runtime + `--timestamp`로
  합니다.
- 공증은 `notarytool submit --wait` 후 `stapler staple`로 합니다. 받은
  DMG를 `spctl -a -t execute`로 검사해 `Notarized Developer ID`가
  나와야 완료입니다.
- 볼륨 이름은 표시 이름(공백 허용)입니다.
- 최소 macOS 버전은 `macos/Podfile`과 Xcode 설정을 같은 값으로 맞추고,
  릴리스 노트 헤더에 적습니다.
- 메뉴바 전용 앱(MacBroom)은 `LSUIElement = true`로 둡니다. 이런 앱도
  정보 창 진입 경로는 필요합니다 ([about-dialog.md](about-dialog.md)).

### 3. Windows (Inno Setup)

템플릿 [`../desktop/installer/windows/app.iss`](../desktop/installer/windows/app.iss)
기준이며, 아래 항목을 필수로 둡니다.

| 지시어 | 값 |
|---|---|
| `AppId` | 앱마다 새 GUID. 릴리스 후 변경 금지 |
| `AppName` | 표시 이름. CI가 `AppInfo.xcconfig`의 `PRODUCT_NAME`에서 읽습니다 (dove-zip 방식). `pubspec.yaml`의 `name:`을 쓰면 snake_case가 됩니다 |
| `AppVersion`, `VersionInfoVersion` | 태그에서 `v`를 뺀 값 |
| `AppPublisher`, `AppPublisherURL`, `AppCopyright` | [identity.md](identity.md) 값 |
| `OutputBaseFilename` | `{#MyFileName}-{#MyAppVersion}-windows-x64-setup` |
| `SetupIconFile`, `UninstallDisplayIcon` | 앱 아이콘 |
| `[Languages]` | `english` + `korean`. 설치 프로그램 문구는 이 파일의 번역을 따르고 `.iss`에 한국어를 하드코딩하지 않습니다 |

- 설치 위치는 `{autopf}\<표시 이름>`입니다.
- 바탕화면 아이콘은 선택 항목이고 기본값은 체크 해제입니다.
- 코드 서명은 아직 하지 않습니다. SmartScreen 안내는 릴리스 노트 헤더에
  적습니다.
- WiX, MSIX는 쓰지 않습니다. allwinner의 `.wxs`는 검증되지 않았으므로
  지웁니다.

### 4. Linux

- 형식은 `build/linux/x64/release/bundle`을 `<FileName>/` 폴더로 묶은
  tar.gz입니다.
- 번들 안에 다음 두 파일을 **함께 넣습니다** (지금은 어느 앱도 넣지 않음).
  - `<FileName>/share/icons/hicolor/256x256/apps/<app-id>.png`
  - `<FileName>/share/applications/<app-id>.desktop`
  - `<app-id>`는 [identity.md](identity.md)의 식별자이고, `.desktop`
    파일 이름은 `APPLICATION_ID`와 같아야 GNOME이 창과 아이콘을
    연결합니다.
- AppImage, deb, rpm은 요청이 생길 때 추가합니다.

### 5. Android / iOS

[`../mobile/`](../mobile/) 템플릿 방식입니다. Android는 AAB만 Play 내부
테스트 트랙으로, iOS는 TestFlight로 보냅니다. 파일 이름은 스토어로 바로
올라가므로 Flutter 기본값을 그대로 씁니다. 사이드로딩용 APK가 필요할
때만 위 1번 규칙으로 이름을 붙여 Release에 첨부합니다.

### 6. 로컬 릴리스 스크립트

CI와 다른 경로로 산출물을 만들지 않습니다. `scripts/release.sh`처럼 로컬
전용 릴리스 스크립트(MacBroom, allwinner)가 있는 앱은, CI로 옮긴 뒤 로컬
스크립트를 **개발용 빌드 스크립트**(`scripts/build-app*.sh`)로만
남깁니다.
