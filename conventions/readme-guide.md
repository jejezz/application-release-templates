# README 가이드

기준은 **MacBroom(garbage-cleaner-for-mac-flutter)의 README**입니다. 앱들 중
처음 보는 사람을 가장 빨리 설득하는 README이고, Show HN 게시용으로 다듬어진
것입니다. 이 문서는 그 구성을 규칙으로 옮기고, 만드는 데 필요한 도구를
[`common/tool/readme/`](../common/tool/readme/)에 둡니다.

## 현재 상태

| 앱 | 언어 | 첫 화면 (아이콘·한 줄 소개·배지·데모) | 스크린샷 | 설치 안내 |
|---|---|---|---|---|
| MacBroom | en | ✓ 전부, 데모 GIF 포함 | 2장 나란히 | ✓ Gatekeeper 안내 포함 |
| daylight | ko + en | 배지 | ✓ | OS별 |
| allwinner | ko + en | — | — | 릴리즈 절 |
| dove-zip | ko | — | — | 릴리스 절 (개발자용) |
| portside | ko | — | — | 릴리스 만들기 (개발자용) |
| saturn | ko (322줄) | — | — | 개발 문서가 README에 섞여 있음 |

대부분 README가 **개발자 노트**로 시작해서, 앱이 무엇인지와 어떻게 받는지가
뒤로 밀려 있습니다.

## 규칙

### 1. 언어: `README.md`는 영어, `README.ko.md`는 한국어

- GitHub, 검색, Show HN에서 처음 보이는 파일은 `README.md`이므로 영어로
  씁니다 (MacBroom 방식).
- 한국어판은 `README.ko.md`입니다. daylight의 `README.en.md` 방식을
  뒤집은 것입니다.
- 두 파일 모두 배지 바로 아래에 언어 전환 링크를 둡니다:
  `English · 한국어`.
- 내용은 같게 유지합니다. 한쪽을 고치면 같은 PR에서 다른 쪽도 고칩니다.
- 스크린샷은 영어 UI로 찍어 두 파일이 같은 이미지를 씁니다. 한국어 UI
  스크린샷이 따로 필요하면 `*.ko.png`로 둡니다.
- 예외: 공개 배포하지 않는 내부 앱(saturn 등)은 `README.md` 하나를 한국어로
  씁니다.

### 2. 구성: 사용자 먼저, 개발자는 아래

| 순서 | 절 | 내용 | 필수 |
|---|---|---|---|
| 1 | **머리** (가운데 정렬) | 앱 아이콘 128px → `<h1>` 표시 이름 → 한 줄 소개 → 배지 → 언어 전환 → 데모 GIF 720px | ✓ |
| 2 | `## Features` | 굵은 기능명 + 대시 + 구체적 설명, 4~6개. 아래에 스크린샷 2장을 360px로 나란히 | ✓ |
| 3 | `## Install` | OS별 받을 파일 표, 서명·보안 경고 넘기는 법 | ✓ |
| 4 | `## How it works` | 흥미로운 기술 선택 2~4문장. 없으면 뺍니다 | 선택 |
| 5 | `## Development` | 실행 명령, 추가 도구, 구조 문서 링크, 릴리스 한 줄 | ✓ |
| 6 | 확장 방법 | "Adding a …" 같은 짧은 레시피 (MacBroom의 "Adding a junk category") | 선택 |
| 7 | `## Credits` | 글꼴, 아이콘 등 에셋 출처 | ✓ |
| 8 | `## License` | `[MIT](LICENSE) © <연도> Jongyun Ahn` | ✓ |

첫 화면(스크롤 전)이 다음 세 질문에 답해야 합니다. **무엇인가**(한 줄
소개), **어떻게 생겼나**(데모), **어떻게 받나**(배지 → releases/latest).

### 3. 문장

- **한 줄 소개**는 무엇이고, 누구를 위한 것이며, 무엇을 더 잘하는지를 한
  문장에 담습니다. 사람들이 검색할 말은 굵게 씁니다.
  - 예 (MacBroom): "A free, open-source **CleanMyMac alternative for
    macOS** — a one-click menubar app that clears caches…"
- **기능**은 구체적으로 씁니다. "빠른 스캔"보다 "`du -sk`로 50만 개 파일
  트리를 몇 초에" 쪽이 낫습니다. 이름, 숫자, 지원 형식을 적습니다.
- 사용자에게 불리한 사실은 숨기지 않고 **해결 방법과 함께** 씁니다. 예:
  서명 안 됨, Full Disk Access 필요, App Store 불가.
- 버전 번호가 들어간 파일 이름(`MacBroom-1.0.1.dmg`)을 쓰지 않습니다.
  `<version>`으로 쓰고 releases/latest로 링크합니다. 적힌 버전은 금방
  낡습니다.
- 개발 문서(아키텍처, 디자인, 릴리스 체크리스트)는 `docs/`나 루트의
  `ARCHITECTURE.md`, `UI_UX.md`로 빼고 링크만 합니다. README 길이는 300줄
  이하를 목표로 합니다.

### 4. 이미지

| 종류 | 파일 | 규격 |
|---|---|---|
| 앱 아이콘 | `assets/icon/app_icon.png` | 아이콘 스크립트가 만든 256px. README에서 `width="128"` |
| 데모 GIF | `docs/screenshots/demo.gif` | 폭 760px, 15fps, **15초 이하, 5 MB 이하** (8 MB 넘으면 검사 실패). 핵심 흐름 하나만 (MacBroom: 스캔 → 정리 → 완료) |
| 스크린샷 | `docs/screenshots/<화면>.png` | 창 캡처를 `frame.py`로 다듬은 1200px. README에서 `width="360"` 2장 나란히, 또는 `width="720"` 1장. 1.5 MB 이하 |
| 라이트·다크 | `frame.py --split`의 결과 | 같은 화면의 두 테마를 대각선으로 나눈 한 장. 테마 전환이 있는 앱은 스크린샷 1장을 이것으로 합니다 |
| 원본 | `docs/screenshots/raw/` | 캡처 원본. 커밋해 두면 다음에 다시 다듬기 쉽습니다 |

- 모든 `<img>`에 `alt`를 씁니다.
  - 데모: "Dove Zip demo: open, extract, done"처럼 흐름을 적습니다.
  - 스크린샷: 화면 이름을 적습니다.
- 스크린샷 속 데이터는 **보여주기용**으로 준비합니다. 개인 경로, 실제 이름,
  토큰이 보이면 안 됩니다. 빈 화면보다는 채워진 화면이 낫습니다.
- 창 크기는 앱의 기본 크기([ui-ux.md](ui-ux.md) §5)로 두고, 모든 캡처를
  같은 크기로 찍습니다.

### 5. 배지

순서: 최신 릴리스 → 다운로드 수 → 플랫폼 → Flutter → 라이선스.
`style=flat-square`로 쓰고, 색은 [theming.md](theming.md)의 팔레트
(primary `4c9dff`, accent `7c5cff`, success `34d399`)를 씁니다. 템플릿에
이미 들어 있습니다. CI 상태 배지는 넣지 않습니다. 릴리스 워크플로는 태그
때만 돌기 때문에 사용자에게 의미가 없습니다.

## 도구

모두 [`common/tool/readme/`](../common/tool/readme/)에 있습니다. `common/`의 다른
도구와 함께 앱의 `tool/readme/`로 복사합니다.

| 도구 | 하는 일 |
|---|---|
| `init_readme.py` | 템플릿에서 `README.md`와 `README.ko.md`를 만듭니다. 표시 이름, 저장소, 플랫폼, 최소 macOS, 연도는 저장소에서 읽어 채우고, 앱에 없는 플랫폼의 설치 안내는 뺍니다. 사람이 써야 할 곳은 `{{TODO: …}}`로 남깁니다 |
| `check_readme.py` | 위 규칙을 검사합니다: 남은 TODO, 깨진 링크, alt 없는 이미지, 필수 절, 언어 전환, 배지, 이미지 용량, H1과 표시 이름 일치, 버전이 박힌 파일 이름 |
| `capture.sh shot <이름>` | 앱 창만 캡처합니다 (창 그림자 없이). 창은 표시 이름으로 찾으므로 앱이 앞에 있지 않아도 됩니다 (macOS) |
| `capture.sh record <초>` | 앱 창 영역을 녹화합니다 (macOS) |
| `capture.sh gif` | 녹화 → 데모 GIF. 영상에서 팔레트를 뽑아 그라데이션 줄무늬를 줄이고, 5 MB를 넘으면 경고합니다 |
| `frame.py` | 원본 캡처를 1200px, 둥근 모서리, 그림자로 다듬습니다. `--split`은 라이트·다크 한 장 |

### 순서

```bash
# 1. README 뼈대 (처음 한 번)
python3 tool/readme/init_readme.py

# 2. 스크린샷: 앱을 띄우고 기본 창 크기로
flutter run -d macos --release
tool/readme/capture.sh shot home-light      # 앱에서 라이트로 바꾸고
tool/readme/capture.sh shot home-dark       # 다크로 바꾸고
tool/readme/capture.sh shot settings
python3 tool/readme/frame.py --split docs/screenshots/raw/home-light.png docs/screenshots/raw/home-dark.png -o home.png
python3 tool/readme/frame.py docs/screenshots/raw/settings.png

# 3. 데모 GIF: 흐름을 연습한 뒤 녹화 (시작 3초 전 안내)
tool/readme/capture.sh record 12
tool/readme/capture.sh gif

# 4. TODO를 채우고 검사
python3 tool/readme/check_readme.py
```

`capture.sh`를 처음 실행하면 터미널 앱에 화면 기록 권한을 요청합니다.
시스템 설정 → 개인정보 보호 및 보안 → 화면 기록에서 허용한 뒤 다시
실행합니다.

### 단계별 기준

README는 앱이 만들어지는 동안 채워지므로 단계마다 요구하는 수준이 다릅니다.

| 단계 | 요구 | 검사 |
|---|---|---|
| 앱 구현 전 | 두 파일, 제목, 언어 전환, 배지, 설치·개발·라이선스 절. 기능·동작 방식은 `{{TODO}}`, 스크린샷·데모는 없어도 됨 | `check_readme.py --stage bootstrap` |
| 프리릴리스 태그 (`v0.1.0-rc.1` 등) | 위와 같음 | CI가 `--stage bootstrap`으로 검사 |
| 정식 릴리스 | 전부. TODO 없음, 이미지 존재(자리 표시 이미지는 경고) | CI가 전체 검사 |

### CI

데스크톱 릴리스 워크플로의 `check` 잡은 `tool/readme/check_readme.py`가
있으면 실행합니다. 프리릴리스 태그는 구조만, 정식 태그는 전체를 검사하고,
어긋나면 릴리스를 만들지 않습니다.
