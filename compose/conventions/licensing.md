# 라이선스 규칙 (Compose)

Flutter용 [licensing.md](../../conventions/licensing.md)의 Compose 판입니다. **앱 자체 라이선스, 에셋
조건, 설치 프로그램 EULA는 Flutter 규약과 같습니다.**

## 같은 것

- 공개 저장소는 MIT, 비공개는 한 줄 고지. `LICENSE`는 필수이고 MIT 원문 그대로 첫 줄(저작권자·연도)만 바꿉니다.
  값은 [identity.md](identity.md)의 `app.copyrightHolder`, `app.firstReleaseYear`입니다.
- README 끝의 `## 라이선스` 절, Icons8·SeoulNamsan·LGPL·GPL 조건, 새 의존성이 MIT/BSD/Apache-2.0/Zlib/OFL이
  아니면 PR 설명에 이유를 적는 규칙.
- MIT 앱의 설치 프로그램에는 라이선스 동의 화면을 넣지 않습니다.

## 달라지는 것

| 항목 | Flutter | Compose |
|---|---|---|
| 오픈소스 라이선스 화면 | `showLicensePage`가 pub 패키지를 자동 수집 | **자동 수집이 없습니다.** Gradle 의존성 라이선스를 모으는 방법은 정보 창을 만들 때 정합니다 (미정) |
| 에셋 라이선스 등록 | `LicenseRegistry.addLicense` | 정보 창 단계에서 정함 (미정). 원문 파일은 `src/main/resources/licenses/`에 두는 것을 예정 |
| 번들되는 런타임 | 해당 없음 | jpackage가 JDK 런타임 이미지를 앱에 **포함**합니다. 우리가 쓰는 Zulu 17은 OpenJDK 기반(GPLv2 + Classpath Exception)이라 고지 대상입니다 — 고지 문구는 원문을 확인해 정합니다 (미검증) |

LICENSE 파일은 앱에서 먼저 만들어 확인했습니다(`daylight-commander-compose/LICENSE`, MIT, `Copyright (c) 2026
Jongyun Ahn`). 정보 창의 오픈소스 라이선스 화면은 아직 구현 전입니다.
