# 공통 파일 (모든 앱)

플랫폼이나 배포 방식과 관계없이 모든 앱에 복사하는 파일입니다. 각 파일이
구현하는 규칙은 [`../conventions/`](../conventions/)에 있습니다.

| 파일 | 앱 안 위치 | 규약 |
|---|---|---|
| [`lib/main.dart`](lib/main.dart) | 새 앱: `lib/main.dart` / 기존 앱: 참고만 | 아래 모든 것의 연결 예시 (창, 라이선스, 설정, 테마, 언어, macOS 메뉴, 앱 바, 빈 상태) |
| [`lib/theme/app_theme.dart`](lib/theme/app_theme.dart) | `lib/theme/app_theme.dart` | [ui-ux.md](../conventions/ui-ux.md), [theming.md](../conventions/theming.md), [fonts.md](../conventions/fonts.md) |
| [`lib/settings/`](lib/settings/) | `lib/settings/` | 테마·언어 저장과 전환 메뉴 — [theming.md](../conventions/theming.md) §3, [localization.md](../conventions/localization.md) §3–5 |
| [`lib/about/app_menu_bar.dart`](lib/about/app_menu_bar.dart) | `lib/about/app_menu_bar.dart` | macOS 앱 메뉴 About — [about-dialog.md](../conventions/about-dialog.md) §1 |
| [`test/`](test/) | `test/` (`<package>`를 바꿈) | 정보 창·설정 테스트 |
| [`lib/update/`](lib/update/) | `lib/update/` | 업데이트 알림 · 내려받기 · 설치 안내 — 아래 '업데이트' 절, `../updater/` 패키지 |
| [`lib/app_identity.dart`](lib/app_identity.dart) | `lib/app_identity.dart` | [identity.md](../conventions/identity.md) |
| [`lib/about/about_dialog.dart`](lib/about/about_dialog.dart) | `lib/about/about_dialog.dart` | [about-dialog.md](../conventions/about-dialog.md) |
| [`lib/about/extra_licenses.dart`](lib/about/extra_licenses.dart) | `lib/about/extra_licenses.dart` | [licensing.md](../conventions/licensing.md) §2 |
| [`l10n/common_ko.arb`](l10n/common_ko.arb), [`common_en.arb`](l10n/common_en.arb) | `lib/l10n/app_ko.arb`, `app_en.arb`에 **키를 합침** | [localization.md](../conventions/localization.md) |
| [`tool/icon/generate_icons.py`](tool/icon/generate_icons.py), [`render_svg.swift`](tool/icon/render_svg.swift) | `tool/icon/` | [icons.md](../conventions/icons.md) |
| [`scripts/bump-version.sh`](scripts/bump-version.sh) | `scripts/bump-version.sh` | [versioning.md](../conventions/versioning.md) §5 |
| [`tool/readme/`](tool/readme/) | `tool/readme/` | [readme-guide.md](../conventions/readme-guide.md) — README 템플릿(en/ko), `init_readme.py`, `check_readme.py`, `capture.sh`(창 캡처·녹화·GIF), `frame.py` |

## 적용 순서

1. **파일 복사**
   ```bash
   T=path/to/application-release-templates/common
   cp -R "$T/lib/." lib/            # 기존 앱이면 main.dart는 빼고 복사
   cp -R "$T/tool" "$T/scripts" .
   mkdir -p test && cp "$T"/test/*.dart test/ && sed -i '' 's/<package>/<앱 package 이름>/' test/*_test.dart
   ```
2. **`lib/app_identity.dart`의 자리 표시자 채우기**
   - `__APP_DISPLAY_NAME__`: `macos/Runner/Configs/AppInfo.xcconfig`의
     `PRODUCT_NAME`과 **정확히 같은 값**. 데스크톱 릴리스 워크플로가 둘을
     비교합니다.
   - `__REPOSITORY__`: GitHub 저장소 이름
3. **l10n 설정** — `l10n.yaml`:
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_ko.arb
   output-class: AppLocalizations
   nullable-getter: false
   untranslated-messages-file: build/untranslated.json
   ```
   `common_*.arb`의 키를 앱의 ARB에 합칩니다. 앱에 ARB가 아직 없으면
   파일을 그대로 `lib/l10n/app_ko.arb`, `app_en.arb`로 복사합니다.
   `(앱별)` / `(per app)`로 시작하는 값은 앱 문구로 바꿉니다. ARB를 고친
   뒤에는 `flutter gen-l10n`을 실행해야 새 키가 코드에 보입니다.
4. **pubspec.yaml**
   ```bash
   flutter pub add package_info_plus url_launcher shared_preferences intl:any 'flutter_localizations:{"sdk":"flutter"}'
   flutter pub add window_manager      # 데스크톱 앱
   ```
   ```yaml
   flutter:
     generate: true
     assets:
       - assets/icon/app_icon.png
       - assets/licenses/
   ```
5. **아이콘** — Icons8 Sticker 글리프 SVG를
   `assets/icon/source_glyph.svg`에 두고 (PNG면 투명 배경 1024px를
   `source_glyph.png`로):
   ```bash
   pip3 install pillow
   python3 tool/icon/generate_icons.py
   ```
6. **라이선스 원문** — `assets/licenses/seoul-namsan.txt` 등을 넣고
   `main()`에서 `runApp` 전에 `registerExtraLicenses()`를 부릅니다.
7. **정보 창 연결** — 앱 바 오른쪽 끝에:
   ```dart
   IconButton(
     tooltip: l10n.aboutTooltip,
     icon: const Icon(Icons.info_outline_rounded),
     onPressed: () => showAppAboutDialog(context,
         tagline: l10n.aboutTagline, description: l10n.aboutDescription),
   ),
   ```
   `aboutTagline`, `aboutDescription`은 앱마다 다른 문구라서 앱 ARB에
   직접 추가합니다.
8. **README** — `python3 tool/readme/init_readme.py`로 `README.md`와
   `README.ko.md`를 만들고 `{{TODO}}`를 채웁니다. `flutter create`가 만든
   기본 README는 그냥 교체되고, 아직 없는 스크린샷·데모 GIF는 "준비 중"
   이미지로 채워져 첫 릴리스 검사를 통과합니다 (캡처로 바꿀 때까지 경고). 스크린샷과 데모 GIF 만드는
   순서는 [readme-guide.md](../conventions/readme-guide.md)의 "도구" 절에 있습니다.

## 업데이트 (데스크톱 앱)

앱 시작 후 하루 1회 서버에 새 버전을 묻고, 있으면 알려서 **동의를 받은 뒤** 내려받아 SHA-256 을 검증하고 설치합니다.
로직은 [`../updater/`](../updater/) 패키지(순수 Dart), 화면과 연결은 `lib/update/` 이고 문구는 ARB 의 `update*` 키입니다.

1. `pubspec.yaml` 에 패키지를 더합니다 (`flutter pub add shared_preferences package_info_plus url_launcher` 는 위에서 이미).
   ```yaml
   dependencies:
     app_updater:
       git:
         url: https://github.com/jejezz/application-release-templates
         path: updater
         ref: updater-v0.1.0   # 업데이트 코드가 들어 있는 태그. conventions-v1 은 그보다 앞선 커밋이라 쓰지 않는다
   ```
   `updater/` 를 바꿀 때마다 새 태그(`updater-v0.1.1` …)를 달고, 앱은 그 태그로 올립니다 (git 의존성은 `ref` 를 고정해야 빌드가 재현됩니다).
2. `lib/update/` 와 `app_identity.dart` 의 `updateServerUrl` · `updateAppId` 를 복사하고, `common_*.arb` 의 `update*` 키를 앱 ARB 에 합칩니다.
3. `main.dart` 처럼 연결합니다: `UpdateService.create()` → `startAutomaticCheck(navigatorKey)`,
   정보 창과 macOS 메뉴에 `onCheckForUpdates` (정보 창 · `AppMenuBar`).
4. 테스트 `test/update_test.dart` 의 `<package>` 를 바꿉니다 (가짜 업데이터라 네트워크 불필요).

- **서버 주소**는 `AppIdentity.updateServerUrl` 기본값이고 `--dart-define=UPDATE_SERVER=https://…/repos` 로 덮어씁니다. **빈 값이면 업데이트 확인을 끕니다** (모바일 앱은 `create()` 가 null).
- **`app` 이름**은 `AppIdentity.repositoryUrl` 의 마지막 경로(저장소 이름)입니다 — 따로 적을 것이 없습니다.
- 릴리스에 `SHA256SUMS.txt` 가 없거나 파일 이름이 [packaging.md](../conventions/packaging.md) §1 을 따르지 않으면 서버가 자동 설치를 막고 "릴리스 페이지에서 받기" 로 안내합니다.
- **macOS 샌드박스:** 규약 앱은 `com.apple.security.app-sandbox = false` 입니다 (portside · dove-zip). `flutter create` 의 기본(샌드박스 켜짐, 네트워크 권한 없음)을 그대로 쓰면 업데이트 확인이 연결되지 않습니다 — 샌드박스를 켠 채로 둔다면 `com.apple.security.network.client` 가 필요하고, DMG 열기(`open`)는 따로 확인해야 합니다.
- 종료는 정식 종료(`exitApplication(cancelable)`)라 앱의 `didRequestAppExit` 를 거칩니다 — 종료 직전에 할 정리(로그 flush · 저장)는 거기에 둡니다. 다르게 하려면 `UpdateService.create()` 대신 직접 만들어 `quitApp` 을 넘깁니다.
- **프리릴리스 버전 함정 (첫 태그 `v0.1.0-rc.1`):** macOS 는 Info.plist 에 숫자만 허용해서 `0.1.0-rc.1+1` 이 `0.1.0.1` 로 들어가고, `PackageInfo.version` 도 그 값이라 `AppUpdater` 가 `ArgumentError: currentVersion: not a version` 을 던진다. `main()` 이 `UpdateService.create()` 를 `runApp` 앞에서 기다리면 **앱이 시작하지 못해 창이 검게 남는다.** 템플릿은 두 겹으로 막는다:
  - `create()` 는 **절대 던지지 않는다** — 버전을 읽을 수 없으면 null(업데이트 확인 끔). 그래서 `main.dart` 에 try/catch 를 따로 둘 필요가 없다.
  - 정확한 버전은 릴리스 워크플로가 태그에서 `--dart-define=APP_VERSION=<버전>` 으로 넣는다 (`desktop/.github/workflows/release.yml`). 없으면 `x.y.z.n` 을 `x.y.z-rc.n` 으로 본다 (규약의 프리릴리스는 rc 뿐). 로컬 `flutter run` 은 define 없이도 이 대체 규칙으로 돈다.
  - 이미 쓰는 앱은 `lib/update/update_service.dart` 와 `release.yml` 의 `flutter build … --dart-define=APP_VERSION=${{ env.VERSION }}` 를 새 템플릿대로 맞춘다. `updater/` 는 바뀌지 않았으므로 `updater-v0.1.0` 태그는 그대로다.
- 시작 시 확인은 첫 화면이 뜬 뒤 5초 뒤에 하고, 실패하면 아무것도 띄우지 않습니다. 수동 "업데이트 확인" 은 항상 결과를 알려 줍니다.

## 검증

이 폴더의 파일은 `flutter create`로 만든 빈 앱(Flutter 3.47.1)에 위 순서대로
적용해서 확인했습니다 (2026-09-24).

- `flutter analyze`: 경고 없음
- 정보 창 위젯 테스트: ko/en 문자열, 저작권, 오픈소스 라이선스 화면 열기
- `generate_icons.py`: 5개 플랫폼 아이콘 생성
- `bump-version.sh`: patch, minor, major, build, 프리릴리스, 더러운 작업
  트리 거부, `Cargo.toml` 동시 갱신

업데이트(`lib/update/`)는 같은 방식으로 `flutter analyze` 경고 없음, 위젯 테스트 25개 통과(기존 7개 포함), `flutter build macos --debug` 성공을 확인했습니다 (2026-10-10).
실제 Windows · Linux 기기와 실제 서버에서의 내려받기 · 설치는 시범 앱에서 확인합니다.

테마·설정·메뉴 코드(`lib/theme/`, `lib/settings/`, `lib/about/app_menu_bar.dart`,
`lib/main.dart`)는 빈 앱에 적용해 `flutter analyze` 경고 없음, 테스트 7개
통과, `flutter build macos` 성공을 확인했습니다. 공통 패키지(`zoomon_ui`)가
생기면 이 파일들은 패키지로 옮깁니다 ([ui-ux.md](../conventions/ui-ux.md) §2).
