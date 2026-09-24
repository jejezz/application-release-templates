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

## 점검 스크립트

세 스킬 모두 [`tools/audit_app.py`](../tools/audit_app.py)로 앱 상태를 잽니다. 스킬
없이 직접 돌려도 됩니다 (앱을 수정하지 않습니다).

```bash
python3 tools/audit_app.py ~/FlutterProject/portside-flutter            # 표로 보기
python3 tools/audit_app.py ~/FlutterProject/portside-flutter --release  # + 릴리스 준비 상태
```

- ❌ 규약 위반, ⚠️ 허용되지만 다름(이미 릴리스된 bundle id 등), ✅ 통과
- 🛑 릴리스를 막는 문제: 릴리스 워크플로의 check 잡이 거부하거나 산출물이
  잘못 나오는 것
