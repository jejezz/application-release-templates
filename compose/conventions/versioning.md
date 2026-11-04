# 버전 규칙 (Compose)

Flutter용 [versioning.md](../../conventions/versioning.md)의 Compose 판입니다. SemVer 해석, build number는
1씩만 증가(되돌리지 않음), 프리릴리스 태그 형식(`v1.5.0-rc.1`, GitHub Release `--prerelease`)은 Flutter 규약과
같습니다. 아래는 **달라지는 것**입니다.

> **Flutter 규약과 다른 점: 시작 버전은 `1.0.0-rc.1+1`입니다** (Flutter 데스크톱은 `0.1.0-rc.1+1`).
> MAJOR는 항상 1 이상이어야 합니다. 이유는 §2.

## 1. 버전의 원본은 `gradle.properties` 하나

```properties
app.version=1.0.0-rc.1
app.build=1
```

- Flutter의 `pubspec.yaml`에 해당합니다. 코드·설치 프로그램에 버전을 따로 적지 않습니다.
- 앱은 빌드 때 채워진 `app.properties` 리소스를 `AppVersion`으로 읽습니다 (`package_info_plus` 자리).
  `build.gradle.kts`의 `tasks.processResources`가 `src/main/resources/app.properties`의 `${version}`,
  `${build}`를 채웁니다. 파일은 [`../common/`](../common/)에 있습니다.
- 리소스를 못 읽으면 `AppVersion.version`은 `0.0.0`이 됩니다. 로컬 빌드임이 한눈에 보이게 하려는 폴백이고,
  테스트(`AppVersionTest`)가 폴백이 아닌지 확인합니다.

## 2. MAJOR는 1 이상: jpackage가 macOS에서 `0.y.z`를 거부합니다

`0.1.0`으로 패키징하면 macOS 번들러가 거부합니다 (이 규약을 만들 때 직접 확인).

```
$ jpackage --app-version 0.1.0 ...
The first number in an app-version cannot be zero or negative.
$ jpackage --app-version 1.1.0 ...   (통과)
```

- 막는 쪽은 Kotlin·Gradle이 아니라 **JDK의 `jpackage`** 입니다. Compose Gradle 플러그인이 같은 규칙을
  **빌드 설정 단계에서** 미리 검사하므로(`Illegal version for 'Dmg': '0.1.0' is not a valid version`),
  `packageDmg`뿐 아니라 `test` 같은 무관한 작업까지 실패합니다.
- Windows(Msi)와 Linux(Deb)는 `0.1.0`도 설정 검사를 통과했지만, macOS를 같이 빌드하는 이상 의미가 없습니다.
  모든 앱이 `1.0.0-rc.1`에서 시작합니다.
- `0.y.z`를 macOS 패키지에만 `1.y.z`로 바꿔 넣는 매핑은 **쓰지 않습니다.** Finder의 버전과 앱 정보 창의
  버전이 달라지고, 실제 `1.0.0`에 도달하면 macOS 쪽 버전이 오히려 내려갑니다(`1.9.0` → `1.0.0`).
- 그래서 `0.y.z` 구간에서 MINOR를 호환이 깨지는 변경에 쓰는 SemVer 관행은 Compose 앱에 적용되지 않습니다.
  [SemVer 해석](../../conventions/versioning.md)의 MAJOR/MINOR/PATCH 표를 그대로 따릅니다.

## 3. 패키지 버전은 접미사를 뗀 숫자 버전

```kotlin
packageVersion = appVersion.substringBefore('-')   // 1.0.0-rc.1 -> 1.0.0
```

- jpackage는 숫자로만 된 `MAJOR.MINOR.PATCH`를 받습니다.
- 그 결과 `1.0.0-rc.1`과 `1.0.0`의 패키지(DMG 파일명, `CFBundleShortVersionString`)가 **같은 `1.0.0`** 이
  됩니다. 둘을 구분하는 것은 태그(`v1.0.0-rc.1`)와 앱 정보 창에 표시되는 `app.version`입니다.
  (Flutter 앱은 macOS에서 `1.5.0-rc.1`을 `1.5.0.1`로 바꿔 넣었습니다.)
- **build number는 패키지 메타데이터에 반영되지 않습니다.** 확인한 값: `CFBundleVersion = 1.0.0`.
  App Store나 Windows `FileVersion`처럼 단조 증가 build number가 필요한 곳에 배포하게 되면
  `packageBuildVersion` 등을 따로 검토합니다 (미검증).

## 4. 프리릴리스

Flutter 규약과 같습니다. 태그는 `v1.5.0-rc.1`, GitHub Release는 `--prerelease`, 정식은 `1.5.0+41`.

## 5. 버전 올리기 절차

Flutter 규약과 같은 흐름입니다(커밋 `chore(release): v1.4.2`, PR로 병합한 뒤 병합 커밋에 태그).
[`../common/scripts/bump-version.sh`](../common/scripts/bump-version.sh)를 앱의 `scripts/`에 복사해 두면
`gradle.properties`의 버전과 build number를 올리고 커밋합니다. 태그는 달지 않습니다.

```bash
scripts/bump-version.sh patch        # 1.4.2+37 -> 1.4.3+38  (프리릴리스에서는 1.5.0-rc.2 -> 1.5.0)
scripts/bump-version.sh minor        # 1.4.2+37 -> 1.5.0+38
scripts/bump-version.sh 1.5.0-rc.1   # 1.4.2+37 -> 1.5.0-rc.1+38
scripts/bump-version.sh build        # 1.4.2+37 -> 1.4.2+38
```

`0.y.z`는 거부하고(§2), 추적 파일에 커밋 안 된 변경이 있으면 멈춥니다.

## 검증 상태

| 항목 | 상태 |
|---|---|
| macOS: `0.1.0` 거부, `1.0.0` DMG 생성 (Zulu 17, Compose 1.9.0, 서명 없음) | 확인 |
| `bump-version.sh` 시나리오 (patch/minor/build/지정/major, 프리릴리스 탈출, `0.x` 거부, 더러운 트리) | 확인 (복사본에서) |
| 빌드된 `app.properties`가 `AppVersion`으로 읽힘 | 확인 (유닛 테스트) |
| Windows MSI, Linux DEB 실제 패키징 | **미검증** — 해당 OS에서 한 번 돌려 봐야 함 |
| build number를 패키지 메타데이터에 반영 | **미검증** (§3) |
