# 앱 공통 규약 (Conventions)

앱마다 기능은 다르지만 **버전, 태그, 릴리스 워크플로, 패키징, 정보 창,
아이콘, 라이선스, 앱 정체성(이름·ID·저작권), UI/UX, 글꼴, 언어, 테마**는
모든 앱이 같은 형식을 따라야 합니다. 이 폴더는 그 형식을 정한 문서이고, 옆의
[`../desktop/`](../desktop/), [`../mobile/`](../mobile/)는 이 규약을
구현한 복사용 템플릿입니다. 규약을 바꿀 때는 템플릿도 같은 커밋에서
바꿉니다.

> **상태: 초안 (2026-09-24)** — 로컬 앱 6개(allwinner-phoenix,
> daylight-commander, dove-zip, garbage-cleaner(MacBroom), portside,
> saturn-mobile-client)의 실제 설정을 비교해서 만들었습니다. 비교 결과는
> [survey-2026-09.md](survey-2026-09.md)에 있습니다. `🟡 TODO` 표시가
> 붙은 항목은 규칙은 정해졌지만 아직 템플릿·공통 패키지로 옮기지 않은
> 작업입니다.

복사용 파일은 세 폴더에 있습니다.

| 폴더 | 내용 |
|---|---|
| [`../common/`](../common/) | 모든 앱: 정보 창, `app_identity.dart`, 추가 라이선스 등록, ARB 키, 아이콘 생성 스크립트, 버전 올림 스크립트, README 템플릿과 스크린샷·GIF 도구 |
| [`../desktop/`](../desktop/) | macOS/Windows/Linux 릴리스 워크플로, Inno Setup 스크립트, Linux `install.sh`, 릴리스 노트 헤더 |
| [`../mobile/`](../mobile/) | iOS/Android 릴리스 워크플로, Fastlane |

## 문서

| 문서 | 다루는 것 |
|---|---|
| [identity.md](identity.md) | 앱 이름 표기, bundle id / applicationId, 게시자, 저작권 문자열 — **다른 모든 문서가 참조하는 값** |
| [versioning.md](versioning.md) | `pubspec.yaml` 버전 형식, build number 규칙, 버전을 읽는 방법 |
| [tagging.md](tagging.md) | 태그 형식, 태그를 다는 시점과 절차, 커밋 메시지 |
| [workflow.md](workflow.md) | GitHub Actions 구성 규칙 (트리거, 잡 구조, Flutter 버전 고정, 릴리스 노트) |
| [packaging.md](packaging.md) | OS별 산출물 형식, 파일 이름, 설치 프로그램 설정 |
| [about-dialog.md](about-dialog.md) | 정보 창(About)의 필수 항목, 배치, 진입 경로 |
| [icons.md](icons.md) | 앱 아이콘 원본과 생성 파이프라인, 앱 안 UI 아이콘 테마 |
| [licensing.md](licensing.md) | 앱 라이선스, 서드파티 고지, 폰트/아이콘 저작자 표시 |
| [ui-ux.md](ui-ux.md) | Saturn 디자인 언어, 토큰, 밀도, 창 크기, 상태 화면, 단축키, 입력 |
| [fonts.md](fonts.md) | SeoulNamsan, 대체 글꼴, 고정폭 글꼴, 사용자 콘텐츠 글꼴 |
| [localization.md](localization.md) | gen-l10n, 한국어 기준 + 영어, 언어 선택 방식, 설정 저장 키, 날짜·숫자 형식 |
| [theming.md](theming.md) | 시스템/라이트/다크, 색 토큰, 전환 UI, 창 테두리 밝기 |
| [readme-guide.md](readme-guide.md) | README 구성(MacBroom 기준), 영어·한국어 두 벌, 스크린샷·데모 GIF 규격, 제작·검사 도구 |

## 새 앱 시작 체크리스트

> 이 체크리스트는 [`flutter-app-bootstrap`](../skills/flutter-app-bootstrap/SKILL.md)
> 스킬이 순서대로 처리합니다. 릴리스 직전 확인과 기존 앱 정비도 스킬이
> 있습니다 — [`../skills/`](../skills/).

새 앱은 **기능 구현 전에** 아래를 먼저 끝냅니다. 순서대로 하면 뒤 단계가
앞 단계 값을 그대로 가져다 씁니다.

1. **정체성 정하기** — [identity.md](identity.md)의 표를 채웁니다
   (표시 이름, 파일용 이름, bundle id, 게시자). 한 번 릴리스한 뒤에는
   bundle id와 Windows `AppId`를 바꾸지 않습니다.
2. **플랫폼 폴더 생성 후 식별자 반영** — `flutter create --org <prefix>`
   를 쓰고, macOS `AppInfo.xcconfig`, Windows `Runner.rc`, Linux
   `CMakeLists.txt`의 이름·저작권·ID를 identity.md 값으로 맞춥니다.
   `com.example`이 남아 있으면 안 됩니다.
3. **LICENSE 추가** — [licensing.md](licensing.md)의 템플릿 그대로.
4. **공통 파일 복사** — [`../common/`](../common/) README의 순서대로
   복사합니다. `lib/app_identity.dart`의 자리 표시자를 채웁니다.
5. **아이콘** — 글리프 SVG를 `assets/icon/source_glyph.svg`에 두고
   `python3 tool/icon/generate_icons.py`를 실행합니다 ([icons.md](icons.md)).
6. **버전** — 데스크톱 `0.1.0-rc.1+1`, 모바일 `0.1.0+1`로 시작
   ([versioning.md](versioning.md)). 이후에는 `scripts/bump-version.sh`로 올립니다.
7. **앱 골격** — 첫 화면을 만들기 전에 아래를 먼저 깝니다.
   - Saturn 테마 토큰과 공통 위젯 ([ui-ux.md](ui-ux.md))
   - SeoulNamsan과 대체 글꼴 ([fonts.md](fonts.md))
   - gen-l10n ko/en과 언어 전환 ([localization.md](localization.md))
   - 시스템/라이트/다크 전환 ([theming.md](theming.md))
   - `window_manager` 창 크기
   - 앱 바 오른쪽 `테마 | 언어 | 정보` 버튼
8. **정보 창** — [about-dialog.md](about-dialog.md) 형식대로. 버전은
   `package_info_plus`로 읽고 코드에 하드코딩하지 않습니다.
9. **릴리스 워크플로 복사** — 데스크톱은 [`../desktop/`](../desktop/),
   모바일은 [`../mobile/`](../mobile/). 시크릿 등록.
10. **README / CLAUDE.md**
   - `python3 tool/readme/init_readme.py`로 README 뼈대를 만듭니다
     ([readme-guide.md](readme-guide.md)). 스크린샷과 데모 GIF는 첫 화면이
     나온 뒤 `tool/readme/capture.sh`로 채웁니다.
   - 앱 저장소 루트의 `CLAUDE.md`에 아래 한 줄을 넣어 Claude가 항상 이
     규약을 먼저 읽게 합니다. 일부 영역만 적용했다면 버전 뒤에 남은 영역을
     적습니다: `conventions-v1 (미적용: 아이콘, l10n·테마, README)`.
   ```markdown
   릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
   https://github.com/jejezz/application-release-templates/tree/main/conventions
   규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1
   ```
11. **첫 태그** — 데스크톱은 프리릴리스 `v0.1.0-rc.1`, 모바일은 `v0.1.0`
    (내부 테스트)을 태그해서 파이프라인 전체가 한 번 끝까지 도는 것을 확인한
    뒤 기능 개발을 시작합니다 ([tagging.md](tagging.md) §1). README는 이
    단계에서 구조만 갖추면 됩니다.

## 규약 버전

규약이 바뀌면 이 저장소에 `conventions-vN` 태그를 붙이고, 각 앱의
`CLAUDE.md`에 적용한 버전을 기록합니다. 어느 앱이 뒤처졌는지 이 값으로
확인합니다.
