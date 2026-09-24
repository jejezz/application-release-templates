# GitHub Actions 워크플로 규칙

구체적인 YAML은 [`../desktop/.github/workflows/release.yml`](../desktop/.github/workflows/release.yml)과
[`../mobile/.github/workflows/`](../mobile/.github/workflows/)에 있습니다.
이 문서는 템플릿을 고치거나 앱에 맞게 바꿀 때 지켜야 할 규칙입니다.

## 현재 상태

| 앱 | 구조 | Flutter 버전 | 태그와 pubspec 검사 | 릴리스 노트 |
|---|---|---|---|---|
| portside | macOS 잡이 릴리스를 만들고, win/linux가 나중에 자산을 업로드 | `3.47.1` 고정 | ✗ | generate-notes |
| daylight | 3개 병렬 빌드 → `release` | `3.47.1` 고정 | ✗ | 헤더 파일 + generate-notes |
| allwinner | 3개 병렬 빌드 → `release` (+ Rust) | stable | ✗ | generate-notes |
| dove-zip | `check-version` → 3개 병렬 빌드 → `release` | stable | ✓ | generate-notes |
| saturn (mobile) | iOS / Android 각각 | stable | ✗ | — |

## 규칙

### 1. 트리거

- 데스크톱은 `push: tags: ["v*.*.*"]`로 트리거하고, 프리릴리스 태그도
  이 패턴에 걸립니다.
- 모바일은 같은 태그 패턴으로 트리거하고, `workflow_dispatch`(build number
  덮어쓰기용)를 허용합니다.
- 데스크톱의 `workflow_dispatch`는 빌드 검증용이라 Release를 만들지
  않습니다 ([tagging.md](tagging.md)).

### 2. 잡 구조: 검사 → 병렬 빌드 → 한 번에 릴리스

```
check ──┬─ build-macos ───┐
        ├─ build-windows ─┼─ release (태그 푸시일 때만: SHA256SUMS + gh release create)
        └─ build-linux ───┘
```

- **검사 잡은 필수입니다.** 데스크톱은 `check`, 모바일은
  `check-version`이라는 이름입니다. dove-zip에서 검증한 잡을 확장한 것으로,
  다음 경우 빌드를 중단합니다.
  - 태그와 `pubspec.yaml` 버전이 다름
  - `Cargo.toml` 버전이 다름 (파일이 있을 때)
  - `lib/app_identity.dart`의 `displayName`이 `PRODUCT_NAME`과 다름
  - 번역이 빠짐 (`l10n.yaml`이 있을 때)
  - README가 규칙에 어긋남 (`tool/readme/check_readme.py`가 있을 때).
    프리릴리스 태그는 구조만, 정식 태그는 전체를 검사합니다
- 데스크톱 `check` 잡은 표시 이름, 파일 이름, 버전, 프리릴리스 여부를
  출력하고, 빌드 잡은 이 값으로 산출물 이름을 짓습니다.
- 모든 플랫폼이 성공했을 때만 `release` 잡이 Release를 만듭니다.
  portside처럼 한 잡이 먼저 Release를 만들고 나머지가 업로드하는 구조는
  쓰지 않습니다. 이 구조에서는 일부 플랫폼 자산만 붙은 릴리스가 남을 수
  있기 때문입니다.
- `release` 잡만 `permissions: contents: write`를 가집니다.

### 3. 도구 버전 고정

```yaml
env:
  FLUTTER_VERSION: "3.47.1"
```

- Flutter는 `channel: stable` 대신 **버전을 고정**합니다. 같은 태그를
  다시 빌드해도 같은 결과가 나와야 하기 때문입니다. 올릴 때는 PR로
  올립니다.
- macOS 러너는 `macos-26`처럼 **이름을 명시**합니다. `macos-latest`는
  Xcode SDK가 예고 없이 바뀝니다.
- 액션은 메이저 버전으로 고정합니다 (`@v4`).

### 4. 릴리스 제목과 노트

- 제목은 `<표시 이름> v1.4.2`입니다 (예: `Dove Zip v1.4.2`).
- 노트는 `.github/release-notes-header.md`(설치 안내) 뒤에
  `--generate-notes`를 붙여 만듭니다. daylight에서 쓰는 방식입니다.
  헤더에는 다음을 적습니다.
  - OS별로 어떤 파일을 받아야 하는지
  - Windows SmartScreen 경고를 넘기는 방법 (코드 서명 전까지)
  - macOS 최소 버전
- 체크섬 파일 `SHA256SUMS.txt`를 함께 첨부합니다 ([packaging.md](packaging.md)).

### 5. 시크릿 이름

템플릿 README에 있는 이름을 그대로 씁니다. 앱마다 다른 이름을 만들지
않습니다.

| 용도 | 이름 |
|---|---|
| macOS 서명·공증 | `MACOS_CERTIFICATE_P12_BASE64`, `MACOS_CERTIFICATE_PASSWORD`, `MACOS_KEYCHAIN_PASSWORD`, `APPLE_ID`, `APPLE_ID_PASSWORD`, `APPLE_TEAM_ID` |
| iOS | `MATCH_*`, `APP_STORE_CONNECT_API_*`, `APPLE_TEAM_ID` |
| Android | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAY_STORE_SERVICE_ACCOUNT_JSON` |

같은 계정의 여러 저장소에서 반복 등록하지 않으려면, 조직 수준 시크릿이나
`gh secret set --repos`를 사용합니다.

### 6. 템플릿과의 관계

- 워크플로 파일 첫 주석에 원본 템플릿과 적용한 규약 버전을 적습니다.
  ```yaml
  # From jejezz/application-release-templates desktop/ @ conventions-v1
  ```
- 앱에서 고친 내용이 다른 앱에도 필요하면 **먼저 템플릿에 반영**한 뒤 앱으로
  가져옵니다. dove-zip의 Windows ISCC 경로 문제가 이 순서로 처리된 사례입니다.
