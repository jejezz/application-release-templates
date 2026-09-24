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

## 검증

이 폴더의 파일은 `flutter create`로 만든 빈 앱(Flutter 3.47.1)에 위 순서대로
적용해서 확인했습니다 (2026-09-24).

- `flutter analyze`: 경고 없음
- 정보 창 위젯 테스트: ko/en 문자열, 저작권, 오픈소스 라이선스 화면 열기
- `generate_icons.py`: 5개 플랫폼 아이콘 생성
- `bump-version.sh`: patch, minor, major, build, 프리릴리스, 더러운 작업
  트리 거부, `Cargo.toml` 동시 갱신

테마·설정·메뉴 코드(`lib/theme/`, `lib/settings/`, `lib/about/app_menu_bar.dart`,
`lib/main.dart`)는 빈 앱에 적용해 `flutter analyze` 경고 없음, 테스트 7개
통과, `flutter build macos` 성공을 확인했습니다. 공통 패키지(`zoomon_ui`)가
생기면 이 파일들은 패키지로 옮깁니다 ([ui-ux.md](../conventions/ui-ux.md) §2).
