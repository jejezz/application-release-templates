# 프레임워크 선택 기준

앱을 새로 시작할 때 어떤 UI 프레임워크를 쓸지 정하는 기준입니다. 이 저장소의
규약·템플릿은 선택된 프레임워크별로 나뉩니다.

## 기본 규칙

| 앱이 지원하는 플랫폼 | 프레임워크 |
|---|---|
| 데스크톱만 (Windows / macOS / Linux) | **Avalonia** |
| 데스크톱 + 스마트폰 | **Flutter** |
| 스마트폰만 (iOS / Android) | **Flutter** |

## 예외

무조건 위 표를 따르는 것은 아닙니다. 예외는 아래 경우입니다.

- **데스크톱 앱에 멀티 윈도우가 필요하다**: 데스크톱 앱은 Avalonia로 만들고,
  스마트폰 앱은 **별도로** Flutter로 만듭니다. (하나의 Flutter 앱으로 데스크톱과
  스마트폰을 함께 내지 않습니다.)
- 그 밖의 예외는 앱 저장소 README에 **이유를 적고** 선택합니다.

## 이 저장소와의 관계

| 프레임워크 | 규약·템플릿 위치 | 상태 |
|---|---|---|
| Flutter | [`conventions/`](conventions/), [`common/`](common/), [`desktop/`](desktop/), [`mobile/`](mobile/), [`skills/`](skills/) | 사용 중 |
| Avalonia | 아직 없음 (`avalonia/` 예정) | 첫 앱을 만들면서 검증한 뒤 일반화 |
| Compose Multiplatform Desktop | [`compose/`](compose/) | **보류** — 이 기준 이전에 시작했고, 당분간 Compose로 개발하지 않음. 폴더는 참고용으로 유지 |

Avalonia 앱도 정체성(이름·ID·저작권), 버전, 태그, 라이선스 같은
**프레임워크와 무관한 규칙**은 [`conventions/`](conventions/)의 문서를 그대로
따릅니다. `pubspec.yaml`·Dart 코드에 묶인 부분만 Avalonia(.NET) 방식으로
대응시킵니다.
