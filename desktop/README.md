# Flutter 데스크톱 릴리스 워크플로 템플릿

macOS/Windows/Linux용 Flutter 데스크톱 앱을 태그 푸시 한 번으로 빌드해서
GitHub Release에 올리는 구성입니다. macOS는 Developer ID 서명 + 공증까지
포함합니다 — [portside-flutter](https://github.com/jejezz/portside-flutter)
저장소에서 실제로 검증한 뒤 이 템플릿으로 일반화했습니다.

모바일(iOS/Android)용 템플릿은 여기가 아니라 [../mobile/](../mobile/)입니다 — 배포 방식(스토어 심사 vs GitHub Release 직접 배포)이 근본적으로 달라서 별도로 관리합니다.

## 구성

| 것 | 위치 |
|---|---|
| GitHub Actions 워크플로 | [`.github/workflows/release.yml`](.github/workflows/release.yml) |
| 릴리스 노트 머리말 | [`.github/release-notes-header.md`](.github/release-notes-header.md) |
| Windows Inno Setup 스크립트 | [`installer/windows/app.iss`](installer/windows/app.iss) |
| Linux 설치 스크립트 | [`linux/install.sh`](linux/install.sh) |

`release.yml`은 태그(`vX.Y.Z`, `vX.Y.Z-rc.N`)를 푸시하면 다음 순서로 돕니다.

1. **`check`** — 다음 중 하나라도 해당하면 여기서 멈춥니다.
   - 태그가 `pubspec.yaml` 버전과 다름
   - `Cargo.toml` 버전이 다름 (파일이 있을 때)
   - `lib/app_identity.dart`의 표시 이름이 `PRODUCT_NAME`과 다름
   - 번역이 빠짐 (`l10n.yaml`이 있을 때)

   이 잡은 표시 이름(`PRODUCT_NAME`), 파일 이름(표시 이름에서 공백 제거),
   버전을 뒤 잡에 넘깁니다.
2. **`build-macos` / `build-windows` / `build-linux`** 를 병렬로 돌립니다.
3. **`release`** — 셋 다 성공했을 때만 `SHA256SUMS.txt`를 만들고, GitHub
   Release를 한 번에 만듭니다.
   - 제목: `<표시 이름> vX.Y.Z`
   - 노트: 머리말 + 자동 생성 노트
   - 프리릴리스 태그면 `--prerelease`로 만듭니다.

하나라도 실패하면 릴리스가 만들어지지 않습니다. 수동 실행
(`workflow_dispatch`)은 1~2단계만 도는 빌드 확인용이고 릴리스를 만들지
않습니다.

산출물 이름 ([packaging.md](../conventions/packaging.md) §1):
`DoveZip-1.4.2-macos-universal.dmg`, `DoveZip-1.4.2-windows-x64-setup.exe`,
`DoveZip-1.4.2-linux-x64.tar.gz`, `SHA256SUMS.txt`

## 사용 방법

1. macOS/Windows/Linux 플랫폼 폴더가 먼저 있어야 합니다:
   ```bash
   flutter create --platforms=macos,windows,linux .
   ```
2. 이 폴더의 내용을 새 앱 저장소의 같은 경로에 복사합니다.
   - `.github/` → 저장소 루트 `.github/`
     (`workflows/release.yml`, `release-notes-header.md`)
   - `installer/windows/app.iss` → 저장소 루트 `installer/windows/`
   - `linux/install.sh` → 저장소 루트 `linux/`
   - [`../common/`](../common/)도 함께 적용합니다. 특히 아이콘 스크립트가
     만드는 `linux/runner/resources/app_icon.png`가 없으면 Linux 빌드가
     실패합니다.
3. **이름과 식별자를 맞춥니다** ([identity.md](../conventions/identity.md)).
   - `macos/Runner/Configs/AppInfo.xcconfig`의 `PRODUCT_NAME`: 표시 이름.
     CI는 표시 이름과 파일 이름을 여기서 읽습니다.
   - `linux/CMakeLists.txt`의 `APPLICATION_ID`: `com.example.*`이면 CI가
     실패합니다.
4. **`installer/windows/app.iss`에서 두 곳을 고칩니다.** 나머지는 CI가
   넘겨줍니다.
   - `AppId`: GUID를 새로 발급해서 넣습니다.
   - `MyAppURL`: 이 앱의 GitHub 저장소 주소.
   ```powershell
   [guid]::NewGuid()
   ```
   `AppId`는 한 번 릴리즈를 낸 뒤에는 절대 바꾸지 마십시오 — 바꾸면
   Windows가 다음 버전을 다른 앱으로 인식해서 업그레이드/제거가 깨집니다.
5. `.github/release-notes-header.md`의 `__MIN_MACOS__`를 앱의 최소 macOS
   버전으로 바꿉니다.
6. GitHub 저장소 Settings → Secrets and variables → Actions 에 아래
   시크릿을 등록합니다.

   | 플랫폼 | 시크릿 | 비고 |
   |---|---|---|
   | macOS | `MACOS_CERTIFICATE_P12_BASE64` | Developer ID Application 인증서를 `.p12`로 내보낸 뒤 `base64 -i cert.p12 \| pbcopy` |
   | macOS | `MACOS_CERTIFICATE_PASSWORD` | 위 `.p12` 내보낼 때 지정한 암호 |
   | macOS | `MACOS_KEYCHAIN_PASSWORD` | CI가 빌드 중에만 쓰는 임시 키체인 암호 — 아무 문자열이나 새로 만들어서 등록 |
   | macOS | `APPLE_ID` | 노터라이즈용 Apple ID 이메일 |
   | macOS | `APPLE_ID_PASSWORD` | **앱 암호(app-specific password)** — [appleid.apple.com](https://appleid.apple.com)에서 발급. 계정 비밀번호 아님 |
   | macOS | `APPLE_TEAM_ID` | [developer.apple.com/account](https://developer.apple.com/account) → Membership details의 10자리 Team ID (iOS와 같은 값이면 재사용 가능) |
   | Windows | 없음 | 서명하지 않는 인스톨러 — SmartScreen이 "확인되지 않은 게시자" 경고를 띄우지만 "추가 정보 → 실행"으로 넘어갈 수 있음 |
   | Linux | 없음 | tarball만 생성, 서명 개념 자체가 없음 |

   `APPLE_TEAM_ID`는 iOS 템플릿([../mobile/](../mobile/))에서
   이미 등록했다면 같은 값을 그대로 재사용하면 됩니다. 다만 `APPLE_ID`/
   `APPLE_ID_PASSWORD`/인증서는 목적(노터라이즈 vs match)이 다르므로 새로
   준비해야 합니다.

## Developer ID 인증서가 아직 없다면

당장 서명 없이 먼저 배포해보고 싶다면 `release.yml`의 "Import Developer ID
certificate", "Sign app", "Notarize DMG" 세 스텝을 지우십시오. `flutter
build macos --release`가 만드는 애드혹(ad-hoc) 서명 그대로 DMG를 만들어
올리며, 받는 사람 Mac에서는 Gatekeeper가 "확인되지 않은 개발자" 경고를
띄웁니다 — 나중에 인증서가 생기면 이 템플릿의 해당 스텝을 다시 가져오면
됩니다.

## 검증 상태

**conventions-v1 개편 (2026-09-24)**: `check` 잡, 산출물 이름 규칙,
프리릴리스, `SHA256SUMS.txt`, Linux `.desktop`·아이콘·`install.sh`,
Inno Setup 한/영 설치 화면을 더했습니다. 아래 두 가지는 빈 Flutter 앱으로
로컬에서 확인했습니다.
- `check` 잡의 스크립트: 태그 불일치, `Cargo.toml` 불일치, 표시 이름
  불일치, 프리릴리스 판별, 번역 누락 검출
- Linux 패키징 단계와 `install.sh`: 설치와 제거

**GitHub 러너에서 태그 릴리스를 끝까지 돌려 본 것은 아직입니다.** 이
템플릿을 처음 적용하는 앱에서 `v0.1.0`으로 확인하고, 결과를 여기에
적습니다.

이전 버전의 검증 기록:

`build-macos`(서명+공증 포함) / `build-windows` / `build-linux` / `release`
네 잡 모두 [portside-flutter](https://github.com/jejezz/portside-flutter)에서
실제 태그 릴리즈로 끝까지 통과하는 것을 확인했습니다 — 다운로드한 macOS DMG를
`spctl -a -t execute`로 검사해 `accepted, source=Notarized Developer ID`가
뜨는 것까지 확인했습니다 (2026-09-21).

**수정 (2026-09-24)**: [dove-zip-flutter](https://github.com/jejezz/dove-zip-flutter)에
적용하다가 `build-windows`의 "Package installer" 단계가 ISCC의 `You may not
specify more than one script filename` 오류로 실패했습니다. Git Bash가
`/DMyAppName=...` 같은 ISCC 옵션을 POSIX 경로로 보고 Windows 경로로 바꿔
넘긴 것이 원인이라, 이 단계에 `MSYS_NO_PATHCONV=1` /
`MSYS2_ARG_CONV_EXCL=*`를 설정해 인자를 그대로 넘기도록 고쳤습니다(Windows
러너에서 설치 프로그램 생성 확인). 이 설정이 없던 portside 검증 당시에는
드러나지 않았습니다 — 이 템플릿을 이미 복사해 쓰는 앱이 있다면 같은 두 줄을
더하십시오.

## 참고: 나중에 Windows 코드 서명이 필요해지면

fastlane 생태계가 Windows를 사실상 지원하지 않으므로, 코드 서명
인증서(EV 인증서 권장 — SmartScreen 평판이 즉시 쌓임)로 `signtool.exe`를
직접 호출하는 스텝을 `build-windows` 잡에 추가해야 합니다. 지금은 이게
필요해지는 시점에, 그때 쓸 인증서를 기준으로 다시 설계하는 편이 낫습니다.
