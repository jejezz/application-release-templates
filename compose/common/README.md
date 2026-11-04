# 공통 파일 (Compose 앱)

Kotlin + Compose Multiplatform Desktop 앱에 복사하는 파일입니다. 각 파일이 구현하는 규칙은
[`../conventions/`](../conventions/)에 있고, 모두 `daylight-commander-compose`에서 만들어 실행으로 확인한
것입니다(유닛 테스트 포함).

> **상태:** 정체성·버전·LICENSE만 있습니다. 정보 창, 설정, 테마, 업데이터는 앱에서 만들어 확인한 뒤 추가합니다.

| 파일 | 앱 안 위치 | 규약 |
|---|---|---|
| [`scripts/bump-version.sh`](scripts/bump-version.sh) | `scripts/` | [versioning.md](../conventions/versioning.md) §5 |
| [`src/main/resources/app.properties`](src/main/resources/app.properties) | `src/main/resources/` | [versioning.md](../conventions/versioning.md) §1, [identity.md](../conventions/identity.md) §2 |
| [`src/main/kotlin/BuildProperties.kt`](src/main/kotlin/BuildProperties.kt) | `src/main/kotlin/<패키지>/` | 위 리소스를 읽는 유일한 곳 |
| [`src/main/kotlin/AppVersion.kt`](src/main/kotlin/AppVersion.kt) | 〃 | [versioning.md](../conventions/versioning.md) §1 |
| [`src/main/kotlin/AppIdentity.kt`](src/main/kotlin/AppIdentity.kt) | 〃 | [identity.md](../conventions/identity.md) |
| [`src/test/kotlin/`](src/test/kotlin/) | `src/test/kotlin/<패키지>/` | 버전·정체성 형식 검사 (MAJOR ≥ 1 포함) |

Kotlin 파일의 `package art.zoomon.APP_PACKAGE`와 `AppIdentity.REPOSITORY_URL`의 `APP_REPOSITORY`를 앱에 맞게
바꿉니다.

## 앱에 연결하기

**1. `gradle.properties`** — 버전과 정체성의 유일한 원본입니다.

```properties
app.version=1.0.0-rc.1
app.build=1
app.id=art.zoomon.<이름>
app.displayName=<Display Name>
app.fileName=<DisplayName>
app.copyrightHolder=Jongyun Ahn
app.firstReleaseYear=<첫 릴리스 연도>
```

**2. `build.gradle.kts`** — 리소스를 채우고 패키징 메타데이터에 같은 값을 씁니다.

```kotlin
fun prop(name: String): String = providers.gradleProperty(name).get()
val appVersion = prop("app.version")
// ... app.build, app.id, app.displayName, app.fileName, app.copyrightHolder, app.firstReleaseYear 도 같은 방식

version = appVersion

tasks.processResources {
    val props = mapOf("version" to appVersion, "build" to appBuild, "id" to appId,
        "displayName" to appDisplayName, "fileName" to appFileName,
        "copyrightHolder" to copyrightHolder, "firstReleaseYear" to firstReleaseYear)
    inputs.properties(props)
    filesMatching("app.properties") { expand(props) }
}

compose.desktop.application.nativeDistributions {
    packageName = appFileName
    packageVersion = appVersion.substringBefore('-')   // jpackage는 숫자 버전만, MAJOR ≥ 1
    vendor = copyrightHolder
    copyright = "Copyright (C) $firstReleaseYear $copyrightHolder"   // OS 공통 필드라 (C)
    macOS { bundleID = appId }                          // 생략하면 mainClass 패키지에서 ID가 만들어짐
}
```

실제 예시는 `daylight-commander-compose`의 `build.gradle.kts`입니다.

**3. `LICENSE`** — [licensing.md](../conventions/licensing.md)의 MIT 원문, 첫 줄의 연도와 저작권자만 바꿉니다.
