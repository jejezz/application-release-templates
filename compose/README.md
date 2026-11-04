# Compose Multiplatform Desktop 앱

Kotlin + Compose Multiplatform Desktop(JVM) 앱을 위한 규약과 템플릿입니다. Flutter 앱용
([`../conventions/`](../conventions/), [`../common/`](../common/), [`../desktop/`](../desktop/))과
분리해서 관리합니다.

> **상태: 준비 중.** 첫 앱인 `daylight-commander-compose`를 단계별로 만들면서, 실제로 동작을
> 확인한 것만 규약으로 올립니다. Flutter 쪽이 portside로 검증한 뒤 일반화한 것과 같은 방식입니다.

| 폴더 | 내용 | 상태 |
|---|---|---|
| [`conventions/`](conventions/) | Compose 앱 규약 문서와 Flutter 규약 대응표 | 대응표만 있음 |
| `common/` | 복사용 Kotlin 공통 파일 (정보 창, 설정, 테마 등) | 아직 없음 |
| `desktop/` | GitHub Actions 릴리스 워크플로, 설치 프로그램 | 아직 없음 |

## 첫 앱

`daylight-commander-compose` — Flutter 판 `daylight-commander-flutter`를 포팅하며 규약을 검증합니다.
