# Compose 앱 규약

[`../../conventions/`](../../conventions/)(Flutter용)의 각 문서가 Compose 앱에서 어떻게 되는지
정리한 대응표입니다. 앱을 만들면서 동작을 확인한 항목부터 이 폴더에 Compose용 문서로 올립니다.

> **상태: 준비 중.** 아래 표의 "초기 판단"은 Flutter 문서를 읽고 추정한 것이며, 앱에서 확인하기
> 전까지는 확정이 아닙니다. 확정되면 상태를 "작성됨"으로 바꾸고 문서 링크를 답니다.

## 진행 방식

1. 앱(`daylight-commander-compose`)에서 먼저 구현하고 실행으로 확인합니다.
2. 확인된 규칙만 이 폴더에 문서로 올립니다. 구현이 필요한 파일은 `../common/`, `../desktop/`에 둡니다.
3. 앱의 `CLAUDE.md`에 적용한 Compose 규약 버전과 미적용 영역을 적습니다.

## Flutter 규약과 다른 점 (요약)

| 항목 | Flutter | Compose |
|---|---|---|
| 데스크톱 시작 버전 | `0.1.0-rc.1+1` | **`1.0.0-rc.1+1`** — jpackage가 macOS에서 `0.y.z`를 거부함 ([versioning.md](versioning.md) §2) |
| 버전·정체성 원본 | `pubspec.yaml` + `AppInfo.xcconfig` | `gradle.properties`의 `app.*` 하나 |
| 번들 ID | `flutter create`가 만들고 플랫폼별로 맞춤 | `macOS { bundleID }`를 **반드시 명시** (생략하면 코드 패키지에서 생성) |
| Flutter 판과 병행하는 포팅 앱 | — | 번들 ID에 `.compose` 접미사 ([identity.md](identity.md) §3) |

## 대응표

초기 판단: **공유** = 규칙은 Flutter 문서를 그대로 따름, **번역** = 규칙은 같고 구현이 다름,
**신규** = Compose용으로 새로 정해야 함.

| Flutter 문서 | 초기 판단 | Compose에서 달라지는 점 | 상태 |
|---|---|---|---|
| [identity](identity.md) | 번역 | 게시 주체 값은 동일. 원본이 `gradle.properties`, 번들 ID 명시 필수(`.compose` 접미사), 저작권은 `(C)` | **작성됨** |
| tagging | 공유 | 태그 형식·절차 동일 | 미정 |
| [licensing](licensing.md) | 공유 | 앱 라이선스·에셋 조건은 동일. 서드파티 수집과 번들 JDK 고지는 정보 창 단계에서 정함 | **일부 작성됨** |
| ui-ux | 공유 | 디자인 값은 동일, 토큰을 Compose 테마로 표현 | 미정 |
| fonts | 공유 | 폰트 파일 재사용, 번들·로딩 방식이 Compose 리소스로 바뀜 | 미정 |
| localization | 번역 | gen-l10n(ARB) 대신 Compose 문자열 리소스. 정책(ko 기준 + en, 저장 키)은 유지 | 미정 |
| theming / settings / settings-screen | 번역 | 구조·저장 키 동일, 구현은 Kotlin | 미정 |
| about-dialog | 번역 | 필수 항목 동일, 버전은 `package_info_plus` 대신 빌드 산출물에서 읽음 | 미정 |
| window-placement | 번역 | 문제(다중 모니터·배율)는 같고 `window_manager` 대신 `WindowState`/AWT | 미정 |
| icons | 번역 | 생성 파이프라인 재사용 가능성 높음. macOS `.icns`·Windows `.ico` 연결 확인 필요 | 미정 |
| readme-guide | 공유 | 구성·스크린샷 규격 동일 | 미정 |
| [versioning](versioning.md) | 신규 | 원본이 `gradle.properties`. **시작 버전 `1.0.0-rc.1`** (jpackage가 macOS에서 `0.y.z` 거부), 패키지 버전은 접미사를 뗌 | **작성됨** |
| workflow | 신규 | Flutter 설정 대신 `setup-java`(17) + Gradle. 트리거·잡 구조는 참고 | 미정 |
| packaging | 신규 | 파일명 규칙은 유지. macOS universal 불가로 arm64/x64 별도 빌드, 서명·공증은 Compose Gradle 플러그인 | 미정 |

## Flutter 전용이라 대응이 없는 것

- `skills/flutter-app-*` 3개: Compose용 스킬은 규약이 어느 정도 굳은 뒤에 만듭니다.
- `updater/` (Dart 패키지): 업데이트 기능은 앱 쪽 9단계에서 Kotlin으로 새로 설계합니다.
