# 앱 공통 규약 (Conventions)

앱마다 기능은 다르지만 **버전, 태그, 릴리스 워크플로, 패키징, 정보 창,
아이콘, 라이선스, 앱 정체성(이름·ID·저작권)** 은 모든 앱이 같은 형식을
따라야 합니다. 이 폴더는 그 형식을 정한 문서이고, 옆의
[`../desktop/`](../desktop/), [`../mobile/`](../mobile/)는 이 규약을
구현한 복사용 템플릿입니다. 규약을 바꿀 때는 템플릿도 같은 커밋에서
바꿉니다.

> **상태: 초안 (2026-09-24)** — 로컬 앱 6개(allwinner-phoenix,
> daylight-commander, dove-zip, garbage-cleaner(MacBroom), portside,
> saturn-mobile-client)의 실제 설정을 비교해서 만들었습니다. 비교 결과는
> [survey-2026-09.md](survey-2026-09.md)에 있습니다. `🟡 결정 필요` 표시가
> 붙은 항목은 아직 확정되지 않은 선택입니다.

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

## 새 앱 시작 체크리스트

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
4. **아이콘** — 원본을 `assets/icon/`에 두고 생성 스크립트로 모든
   플랫폼 아이콘을 만듭니다 ([icons.md](icons.md)).
5. **버전 `0.1.0+1`** 로 시작 ([versioning.md](versioning.md)).
6. **정보 창** — [about-dialog.md](about-dialog.md) 형식대로. 버전은
   `package_info_plus`로 읽고 코드에 하드코딩하지 않습니다.
7. **릴리스 워크플로 복사** — 데스크톱은 [`../desktop/`](../desktop/),
   모바일은 [`../mobile/`](../mobile/). 시크릿 등록.
8. **README / CLAUDE.md** — 앱 저장소 루트의 `CLAUDE.md`에 아래 한 줄을
   넣어 Claude가 항상 이 규약을 먼저 읽게 합니다.
   ```markdown
   릴리스·버전·패키징·정보 창·아이콘·라이선스는
   https://github.com/jejezz/application-release-templates/tree/main/conventions
   규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1
   ```
9. **첫 릴리스 `v0.1.0`** 을 태그해서 파이프라인 전체가 한 번 끝까지
   도는 것을 확인한 뒤 기능 개발을 시작합니다.

## 규약 버전

규약이 바뀌면 이 저장소에 `conventions-vN` 태그를 붙이고, 각 앱의
`CLAUDE.md`에 적용한 버전을 기록합니다. 어느 앱이 뒤처졌는지 이 값으로
확인합니다.
