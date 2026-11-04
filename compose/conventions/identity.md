# 앱 정체성 (Compose)

Flutter용 [identity.md](../../conventions/identity.md)의 Compose 판입니다. 게시 주체(식별자 접두어
`art.zoomon`, 게시자·저작권자 `Jongyun Ahn`, 웹사이트는 앱 저장소 URL), 표시 이름 규칙, 저작권 문자열
형식(`Copyright © <첫 릴리스 연도> <저작권자>`), "릴리스 후 바꾸지 않는 값" 원칙은 Flutter 규약과 같습니다.
아래는 **Compose에서 달라지는 것**입니다.

## 1. 이름 표기

| 용도 | 형식 | 예 | 쓰는 곳 |
|---|---|---|---|
| 표시 이름 | 띄어쓰기 있는 Title Case | `Daylight Commander` | 창 제목, 정보 창, 릴리스 제목 |
| 파일 이름 | 공백 없는 PascalCase | `DaylightCommander` | `packageName`(앱 번들·DMG 이름), 설정 폴더 |
| Kotlin 패키지 | 소문자, 구분자 없음 | `art.zoomon.daylightcommander` | 소스 패키지, `mainClass` |
| 저장소 / Gradle 프로젝트 | kebab-case + `-compose` | `daylight-commander-compose` | GitHub, `rootProject.name` |

## 2. 원본은 `gradle.properties` 하나

```properties
app.id=art.zoomon.daylightcommander.compose
app.displayName=Daylight Commander
app.fileName=DaylightCommander
app.copyrightHolder=Jongyun Ahn
app.firstReleaseYear=2026
```

- 빌드 스크립트(패키징 메타데이터)와 코드(`AppIdentity`)가 모두 여기서 읽습니다. 버전과 같은 방식이라
  `app.properties` 리소스를 거칩니다 ([versioning.md](versioning.md) §1). 두 곳에 따로 적혀 어긋나는 일을
  막으려는 것입니다.
- `AppIdentity`는 값이 없으면 즉시 실패합니다(`BuildProperties.require`). 버전의 `0.0.0` 폴백과 달리
  이름이 빈 채로 출시되는 것을 막기 위해서입니다.
- 파일은 [`../common/`](../common/)에 있습니다.

## 3. 번들 ID는 반드시 명시한다

`macOS { bundleID = ... }`를 지정하지 않으면 jpackage는 **`mainClass`의 패키지에서 ID를 만듭니다.**
확인한 값: 지정 전 `CFBundleIdentifier = art.zoomon.daylightcommander`, 지정 후
`art.zoomon.daylightcommander.compose`. Flutter 판과 포팅 앱이 같은 코드 패키지를 쓰면 의도하지 않게 같은
ID가 되므로 항상 명시합니다.

- 형식: `art.zoomon.<이름>` (Flutter 규약 §3과 같음).
- **Flutter 판과 병행하는 포팅 앱은 `.compose`를 붙입니다.** 같은 맥에 두 앱을 나란히 설치해 동작을 비교할 수
  있고, 설정 폴더와 macOS 권한(TCC)이 섞이지 않습니다. Flutter 판을 나중에 대체하기로 하면 사용자 설정이
  이어지지 않는 점을 감수해야 합니다.
- 식별자는 릴리스 후 바꾸지 않습니다. Windows 업그레이드 식별자(MSI의 upgrade UUID)도 마찬가지입니다 —
  Compose 설정 이름과 값은 패키징 단계에서 정합니다 (미검증).

## 4. 저작권 문자열

- 코드(정보 창): `Copyright © 2026 Jongyun Ahn` — `AppIdentity.copyright`.
- 패키징 메타데이터: jpackage의 `copyright`는 **OS 공통 한 필드**라서 Windows 인코딩 문제를 피해
  `(C)`를 씁니다. 확인한 값: `NSHumanReadableCopyright = Copyright (C) 2026 Jongyun Ahn`.
  지정하지 않으면 `Copyright (C) 2026`처럼 **저작권자가 빠집니다.** `vendor`도 함께 지정합니다.

## 5. macOS 디버그 빌드의 `.dev` 식별자 (Flutter §7)

Flutter 규약의 `.dev` 규칙은 디버그 앱이 릴리스 앱과 같은 번들 ID로 등록되는 문제에서 나왔습니다.
`./gradlew run`은 번들 없이 `java` 프로세스로 실행되므로 그 전제가 없습니다 (추정). 로컬 네트워크에 접속하는
기능(SSH, SIP 등)을 만들 때 권한 동작을 확인한 뒤 확정합니다.

## 6. 설정 저장 위치

Flutter 규약 §6과 같습니다. 폴더 이름에 **파일 이름**(`DaylightCommander`)을 씁니다.

- macOS: `~/Library/Application Support/<FileName>`
- Windows: `%APPDATA%\<FileName>`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/<FileName>`
