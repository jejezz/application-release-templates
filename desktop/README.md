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
| Windows Inno Setup 스크립트 | [`installer/windows/app.iss`](installer/windows/app.iss) |

`release.yml`은 태그(`v*.*.*`)를 푸시하면 `build-macos` / `build-windows` /
`build-linux` 세 잡을 병렬로 돌려 각각 워크플로 아티팩트로 올리고, 셋 다
성공했을 때만 마지막 `release` 잡이 한 번에 모아서 GitHub Release를
만듭니다. 하나라도 실패하면 릴리즈 자체가 생성되지 않습니다 — 플랫폼별로
따로 릴리즈를 만들지 않기 때문에 일부 자산만 올라간 릴리즈가 남는 일이
없습니다.

## 사용 방법

1. macOS/Windows/Linux 플랫폼 폴더가 먼저 있어야 합니다:
   ```bash
   flutter create --platforms=macos,windows,linux .
   ```
2. 이 폴더의 내용을 새 앱 저장소의 같은 경로에 복사합니다.
   - `.github/workflows/release.yml` → 저장소 루트 `.github/workflows/`
   - `installer/windows/app.iss` → 저장소 루트 `installer/windows/`
3. **`installer/windows/app.iss`에서 `AppId`의 GUID를 새로 발급해서
   바꿉니다** — 이 템플릿에서 손으로 고쳐야 하는 곳은 이거 하나뿐입니다
   (앱 표시 이름/실행 파일 이름은 CI가 `pubspec.yaml`/`CMakeLists.txt`에서
   자동으로 읽습니다).
   ```powershell
   [guid]::NewGuid()
   ```
   한 번 릴리즈를 낸 뒤에는 절대 바꾸지 마십시오 — 바꾸면 Windows가 다음
   버전을 다른 앱으로 인식해서 업그레이드/제거가 깨집니다.
4. GitHub 저장소 Settings → Secrets and variables → Actions 에 아래
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

`build-macos`(서명+공증 포함) / `build-windows` / `build-linux` / `release`
네 잡 모두 [portside-flutter](https://github.com/jejezz/portside-flutter)에서
실제 태그 릴리즈로 끝까지 통과하는 것을 확인했습니다 — 다운로드한 macOS DMG를
`spctl -a -t execute`로 검사해 `accepted, source=Notarized Developer ID`가
뜨는 것까지 확인했습니다 (2026-09-21).

## 참고: 나중에 Windows 코드 서명이 필요해지면

fastlane 생태계가 Windows를 사실상 지원하지 않으므로, 코드 서명
인증서(EV 인증서 권장 — SmartScreen 평판이 즉시 쌓임)로 `signtool.exe`를
직접 호출하는 스텝을 `build-windows` 잡에 추가해야 합니다. 지금은 이게
필요해지는 시점에, 그때 쓸 인증서를 기준으로 다시 설계하는 편이 낫습니다.
