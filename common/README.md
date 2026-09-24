# 공통 파일 (모든 앱)

플랫폼이나 배포 방식과 관계없이 모든 앱에 복사하는 파일입니다. 각 파일이
구현하는 규칙은 [`../conventions/`](../conventions/)에 있습니다.

| 파일 | 앱 안 위치 | 규약 |
|---|---|---|
| [`lib/app_identity.dart`](lib/app_identity.dart) | `lib/app_identity.dart` | [identity.md](../conventions/identity.md) |
| [`lib/about/about_dialog.dart`](lib/about/about_dialog.dart) | `lib/about/about_dialog.dart` | [about-dialog.md](../conventions/about-dialog.md) |
| [`lib/about/extra_licenses.dart`](lib/about/extra_licenses.dart) | `lib/about/extra_licenses.dart` | [licensing.md](../conventions/licensing.md) §2 |
| [`l10n/common_ko.arb`](l10n/common_ko.arb), [`common_en.arb`](l10n/common_en.arb) | `lib/l10n/app_ko.arb`, `app_en.arb`에 **키를 합침** | [localization.md](../conventions/localization.md) |
| [`tool/icon/generate_icons.py`](tool/icon/generate_icons.py) | `tool/icon/generate_icons.py` | [icons.md](../conventions/icons.md) |
| [`scripts/bump-version.sh`](scripts/bump-version.sh) | `scripts/bump-version.sh` | [versioning.md](../conventions/versioning.md) §5 |
| [`tool/readme/`](tool/readme/) | `tool/readme/` | [readme-guide.md](../conventions/readme-guide.md) — README 템플릿(en/ko), `init_readme.py`, `check_readme.py`, `capture.sh`(창 캡처·녹화·GIF), `frame.py` |

## 적용 순서

1. **파일 복사**
   ```bash
   T=path/to/application-release-templates/common
   cp -R "$T/lib/." lib/
   cp -R "$T/tool" "$T/scripts" .
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
4. **pubspec.yaml**
   ```bash
   flutter pub add package_info_plus url_launcher intl:any 'flutter_localizations:{"sdk":"flutter"}'
   ```
   ```yaml
   flutter:
     generate: true
     assets:
       - assets/icon/app_icon.png
       - assets/licenses/
   ```
5. **아이콘** — 글리프(투명 배경, 512px 이상)를
   `assets/icon/source_glyph.png`에 두고:
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
   `README.ko.md`를 만들고 `{{TODO}}`를 채웁니다. 스크린샷과 데모 GIF 만드는
   순서는 [readme-guide.md](../conventions/readme-guide.md)의 "도구" 절에 있습니다.

## 검증

이 폴더의 파일은 `flutter create`로 만든 빈 앱(Flutter 3.47.1)에 위 순서대로
적용해서 확인했습니다 (2026-09-24).

- `flutter analyze`: 경고 없음
- 정보 창 위젯 테스트: ko/en 문자열, 저작권, 오픈소스 라이선스 화면 열기
- `generate_icons.py`: 5개 플랫폼 아이콘 생성
- `bump-version.sh`: patch, minor, major, build, 프리릴리스, 더러운 작업
  트리 거부, `Cargo.toml` 동시 갱신

아직 없는 것: 테마 토큰, 언어·테마 전환 위젯. 이 둘은 공통 패키지
(`zoomon_ui`) 여부를 정한 뒤 추가합니다 ([ui-ux.md](../conventions/ui-ux.md) §2).
