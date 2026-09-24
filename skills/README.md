# Claude Code 스킬

규약([`../conventions/`](../conventions/))을 앱에 적용하는 일을 단계별 스킬 세 개로
나눴습니다. 스킬은 이 저장소의 템플릿과 [`../tools/audit_app.py`](../tools/audit_app.py)를
직접 읽으므로, 이 저장소를 한 곳에 받아 두고 링크로 등록합니다.

| 스킬 | 단계 | 이렇게 말하면 실행됩니다 |
|---|---|---|
| [`flutter-app-bootstrap`](flutter-app-bootstrap/SKILL.md) | 앱 구현 전 | "새 앱 만들자: Photo Sorter, 데스크톱", "이 빈 프로젝트에 규약 깔아줘" |
| [`flutter-app-release-check`](flutter-app-release-check/SKILL.md) | 릴리스 직전 | "릴리즈 해도 돼?", "v1.3.0 태그 달기 전에 확인해줘" |
| [`flutter-app-convention-audit`](flutter-app-convention-audit/SKILL.md) | 기존 앱 정비 | "portside 규약에 맞는지 보고 고쳐줘" |

`/flutter-app-bootstrap`처럼 이름으로 직접 부를 수도 있습니다.

## 설치

```bash
git clone https://github.com/jejezz/application-release-templates ~/FlutterProject/application-release-templates
~/FlutterProject/application-release-templates/tools/install_skills.sh
```

`~/.claude/skills/<스킬>`이 이 저장소의 `skills/<스킬>`을 가리키는 링크가 됩니다.
스킬은 실행할 때마다 이 저장소를 `git pull --ff-only`로 갱신하므로, 규약이나
템플릿을 고치면 모든 앱에서 바로 반영됩니다. 제거는 `install_skills.sh --remove`.

## 스킬별 범위

| 영역 | 앱 구현 전 (`bootstrap`) | 릴리스 직전 (`release-check`) | 기존 앱 정비 (`convention-audit`) |
|---|---|---|---|
| 이름·식별자·저작권·LICENSE | 만듦 (식별자 통일, TEST_HOST, 창 제목) | 점검만 | 표시 문자열만 고침 — 릴리스된 식별자·AppId는 유지 |
| 버전 | 데스크톱 `0.1.0-rc.1+1`, 모바일 `0.1.0+1` | 커밋·diff로 다음 버전 제안, 브랜치에서 올림 | `main`을 태그에 맞춤 (태그는 안 옮김) |
| 정보 창·테마·언어·글꼴·창 | `common/lib`로 전부 만듦 | 점검 안 함 (부채로 한 줄) | 고른 영역만, 설정 키는 이전 |
| 아이콘 | 글리프로 생성 (없으면 임시) | 점검 안 함 | 글리프가 있을 때만 (없으면 임시 대안) |
| 워크플로·설치 프로그램 | 복사, GUID 발급 | 🛑 판정, 시크릿, 최근 CI | 템플릿으로 교체, 앱 고유 단계 유지 |
| README | **구조만** (기능·동작 방식·스크린샷은 TODO로 남김) | 완성 필수 (프리릴리스 태그는 구조만) | 교체, 기존 개발 문서는 옮김 |
| CLAUDE.md | 만듦 | — | 적용 버전·미적용 영역 기록 |
| push · PR · 태그 | 매번 확인. 첫 태그는 데스크톱 `v0.1.0-rc.1` | 매번 확인, 태그는 이름까지 재확인 | 매번 확인, 태그 안 함 |
| 앱 기능 코드 | 안 씀 | 안 씀 | 안 씀 |

## 단계별 점검 항목

스킬은 [`tools/audit_app.py`](../tools/audit_app.py)를 자기 단계로 실행합니다
(`--stage bootstrap | release | maintain`). 단계마다 점검하는 것이 다릅니다.

| 점검 | `bootstrap` (앱 구현 전) | `release` (릴리스 직전) | `maintain` (기존 앱 정비) |
|---|---|---|---|
| 이름·식별자·저작권 (`identity.*`) | ✓ | ✓ | ✓ |
| 버전 형식·태그·하드코딩 (`version.*`) | ✓ + 시작 버전 | ✓ | ✓ |
| 워크플로·설치 프로그램 (`workflow.*`, `packaging.*`) | ✓ | ✓ (🛑/⤴ 구분) | ✓ |
| 정보 창·라이선스·아이콘·글꼴·테마·창 | ✓ | ✓ (부채) | ✓ |
| 번역 설정·키 일치 (`l10n.setup/parity`) | ✓ | ✓ | ✓ |
| 코드에 남은 한국어 문자열 (`l10n.hardcoded`) | — (아직 화면이 없음) | ✓ | ✓ |
| README 구조 (파일 2개, 제목, 언어 전환, 배지, 설치·개발·라이선스 절) | ✓ | ✓ | ✓ |
| README 내용 (기능·동작 방식 TODO, 스크린샷·데모 이미지) | — (기능이 생긴 뒤) | ✓ (프리릴리스 태그는 —) | ✓ |
| 릴리스 준비 (작업 트리, 원격에 없는 커밋, 버전 올림, 태그, 시크릿) | — | ✓ | — |
| 판정 (go · bump · hold) | — | ✓ | — |
| 목표 | ❌ 0개 | 🛑 0개 | 부채 목록 → 고를 영역 |

CI의 README 검사도 같은 기준입니다: 프리릴리스 태그(`vX.Y.Z-rc.N`)는 구조만,
정식 태그는 전체 ([readme-guide.md](../conventions/readme-guide.md) "단계별 기준").

## 점검 스크립트

세 스킬 모두 [`tools/audit_app.py`](../tools/audit_app.py)로 앱 상태를 잽니다. 스킬
없이 직접 돌려도 됩니다 (앱을 수정하지 않습니다).

```bash
python3 tools/audit_app.py ~/FlutterProject/portside-flutter                    # 기존 앱 정비 기준 (기본)
python3 tools/audit_app.py ~/FlutterProject/portside-flutter --stage release    # 릴리스 직전 기준 + 판정
python3 tools/audit_app.py ~/FlutterProject/new-app-flutter --stage bootstrap   # 앱 구현 전 기준
```

- ❌ 규약 위반, ⚠️ 허용되지만 다름(이미 릴리스된 bundle id 등), ✅ 통과
- 🛑 이번 릴리스를 막는 문제: 앱이 지금 쓰는 워크플로의 check 잡이 거부하거나
  산출물·버전이 잘못 나오는 것
- ⤴ 워크플로를 conventions-v1으로 올릴 때 함께 해야 하는 것
