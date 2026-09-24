# 태그와 커밋 규칙

## 현재 상태에서 드러난 문제

- MacBroom의 `v1.0.2` 태그는 `main`에 병합되지 않은 브랜치를 가리킵니다.
  그래서 `main`의 버전은 여전히 1.0.1입니다.
- daylight-commander의 수동 실행(`workflow_dispatch`)은
  `manual-20260923…` 같은 이름으로 릴리스를 만듭니다. 이런 릴리스는
  버전 체계 밖에 있습니다.
- annotated 태그와 lightweight 태그가 섞여 있습니다 (dove-zip의 v0.1.0은
  annotated, v0.1.1은 lightweight).
- 버전을 올리는 커밋의 메시지가 `update version`, `version update 1.2.5`,
  `v0.2.4`, `Bump version to 0.1.8`, `chore: 1.2.9로 버전 올림` 등 제각각입니다.

## 규칙

### 1. 태그 형식

| 종류 | 형식 | GitHub Release |
|---|---|---|
| 정식 | `vMAJOR.MINOR.PATCH` (예: `v1.4.2`) | 일반 릴리스 |
| 프리릴리스 | `vX.Y.Z-rc.N`, `vX.Y.Z-beta.N` | `--prerelease` |

- 태그 문자열에서 `v`를 뺀 값은 `pubspec.yaml`의 `version`에서
  `+build`를 뺀 값과 **정확히 같아야 합니다.** CI가 이를 검사하고, 다르면
  빌드를 중단합니다 ([workflow.md](workflow.md)).
- build number는 태그에 넣지 않습니다.

### 2. 태그를 다는 위치와 방법

```bash
git switch main && git pull
git tag -a v1.4.2 -m "Dove Zip 1.4.2"
git push origin v1.4.2
```

- **`main`에 병합된 버전 올림 커밋에만** 태그를 답니다. 작업 브랜치에는
  달지 않습니다.
- 항상 annotated 태그(`-a`)를 쓰고, 메시지는 `<표시 이름> <버전>`입니다.
- 이미 푸시한 태그는 옮기거나 지우지 않습니다. 릴리스가 잘못됐으면 PATCH를
  올려서 새로 릴리스합니다. 예외는 CI가 실패해서 **릴리스가 아예 만들어지지
  않은 경우**뿐이고, 이때는 태그를 지우고 고친 커밋에 다시 달 수 있습니다.

### 3. 버전 체계 밖의 릴리스는 만들지 않음

`workflow_dispatch`는 **빌드 검증용**으로만 씁니다. 수동 실행에서는
아티팩트만 올리고 GitHub Release는 만들지 않습니다.

### 4. 커밋 메시지

🟡 **결정 필요** — 지금 쓰는 스타일은 세 가지입니다: 영어 명령형
(dove, portside, MacBroom), 한국어 서술형(allwinner, saturn), Conventional
Commits + 한국어(daylight). 아래는 제안입니다.

- 형식은 Conventional Commits 접두어 + 한국어 본문입니다.
  `<type>: <무엇을 했는지>`
  - type은 `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, `build`,
    `test` 중 하나입니다.
  - 예: `feat: 압축 해제 진행률 표시`, `fix(windows): 설치 경로 공백 처리`
- 버전 올림 커밋은 `chore(release): v1.4.2`로 통일합니다.
- 접두어를 통일해 두면, 나중에 `--generate-notes` 대신 커밋 기반으로
  CHANGELOG를 자동 생성할 수 있습니다.

### 5. CHANGELOG

지금은 어느 앱도 CHANGELOG를 두지 않고, GitHub `--generate-notes`(PR 제목
목록)에 맡기고 있습니다. 이 방식을 유지하되, 릴리스 노트 앞에 설치 안내를
붙입니다 ([workflow.md](workflow.md)의 릴리스 노트 절).
