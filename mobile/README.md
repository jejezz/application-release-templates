# Flutter 모바일 릴리스 워크플로 템플릿

Fastlane + GitHub Actions로 Flutter 앱을 TestFlight / Play 내부 테스트에 올리는
구성을, 다른 Flutter 앱에도 그대로 옮겨 쓸 수 있게 일반화한 것입니다. 실제로
동작하는 예시는 [saturn-mobile-client-flutter](https://github.com/ptype-co-kr/saturn-mobile-client-flutter)
앱 자체이고 (`android/`, `ios/`, `.github/workflows/`), 그 설정 방법은 그
저장소의 [release-workflow.md](https://github.com/ptype-co-kr/saturn-mobile-client-flutter/blob/main/release-workflow.md)에
자세히 적혀 있습니다. 새 앱에
적용할 때도 그 문서를 같이 보십시오 — 여기 README는 "무엇을 바꿔야 하는지"만
다룹니다.

macOS/Windows/Linux 데스크톱 앱은 여기가 아니라 [../desktop/](../desktop/)를
쓰십시오 —
스토어 심사 없이 GitHub Release로 직접 배포하는 방식이라 구조가 완전히
달라서 별도 템플릿으로 관리합니다.

## 태그와 버전 검사

두 워크플로 모두 `vX.Y.Z` 태그를 푸시하면 돕니다. 먼저 `check-version`
잡이 태그와 `pubspec.yaml` 버전이 같은지 확인하고, 다르면 스토어에 올리지
않고 멈춥니다 ([versioning.md](../conventions/versioning.md)). 수동
실행(`workflow_dispatch`)은 이 검사를 건너뛰고 build number를 덮어쓸 수
있습니다. Flutter 버전은 `env.FLUTTER_VERSION`으로 고정합니다.

## 적용 대상

- **iOS** — fastlane match(인증서) + App Store Connect API Key + TestFlight 업로드
- **Android** — 릴리스 키스토어 + Play Console 서비스 계정 + 내부 테스트 트랙 업로드

## 사용 방법

1. 이 폴더(`mobile/`)의 내용을 새 앱 저장소의 같은 경로에 복사합니다.
   - `.github/workflows/*.yml` → 저장소 루트 `.github/workflows/`
   - `android/*`, `android/fastlane/*` → 저장소 루트 `android/`
   - `ios/*`, `ios/fastlane/*` → 저장소 루트 `ios/`
2. `__APP_IDENTIFIER__` 를 새 앱의 실제 bundle id / applicationId 로 전부
   바꿉니다 (`ios/fastlane/Appfile`, `ios/fastlane/Matchfile`,
   `ios/fastlane/Fastfile`, `android/fastlane/Appfile`).
   ```bash
   grep -rl '__APP_IDENTIFIER__' . | xargs sed -i '' 's/__APP_IDENTIFIER__/com.example.newapp/g'
   ```
3. **Android**: `android/app/build.gradle.kts` 에 서명 설정을 추가합니다. 이
   템플릿은 빌드 스크립트 전체를 대체하지 않습니다 — 앱마다 이미 다른 내용이
   있기 때문입니다. 대신 실제로 적용된 예시를 그대로 참고해서 옮기십시오:
   [`android/app/build.gradle.kts`](https://github.com/ptype-co-kr/saturn-mobile-client-flutter/blob/main/android/app/build.gradle.kts) 상단의
   `import java.io.FileInputStream` 부터 `signingConfigs { … }` /
   `buildTypes { release { … } }` 블록까지가 그 부분입니다. 요지:
   - CI에서는 `ANDROID_KEYSTORE_PATH` 등 환경 변수로 서명 정보를 주입
   - 로컬에서는 `android/key.properties`(git-ignored)로 대체 가능
   - 둘 다 없으면 디버그 서명으로 떨어져 `flutter run --release`가 계속 동작
4. `android/key.properties.example` 을 그대로 복사해 두면 로컬 릴리스 빌드
   방법을 팀원들이 바로 알 수 있습니다.
5. `android/.gitignore` 에 다음이 있는지 확인합니다 (Flutter 기본 템플릿에는
   이미 있습니다):
   ```
   key.properties
   **/*.keystore
   **/*.jks
   play-store-service-account.json
   ```
6. GitHub 저장소 Settings → Secrets and variables → Actions 에 아래 표의
   시크릿을 등록합니다. 값을 어떻게 구하는지는
   [release-workflow.md](https://github.com/ptype-co-kr/saturn-mobile-client-flutter/blob/main/release-workflow.md)를
   그대로 따라 하면 됩니다 —
   앱마다 다른 것은 값뿐이고 절차는 동일합니다.

   | 플랫폼 | 시크릿 |
   |---|---|
   | Android | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_STORE_SERVICE_ACCOUNT_JSON` |
   | iOS | `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION`, `MATCH_PASSWORD`, `APPLE_TEAM_ID`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_CONTENT` |

   iOS는 앱마다 match 인증서 저장소(비공개 git 저장소)가 따로 필요합니다 —
   기존 앱의 저장소를 재사용하지 말고 새 앱용으로 새로 만드십시오. 자세한
   이유는 release-workflow.md의 match 절 참고.

## macOS/Windows/Linux는?

[../desktop/](../desktop/) 참고. 거기 있는
`APPLE_TEAM_ID`는 여기서 이미 등록했다면 같은 값을 재사용할 수 있습니다.
