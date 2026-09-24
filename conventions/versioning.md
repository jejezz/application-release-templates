# 버전 규칙

## 현재 상태에서 드러난 문제

- **버전이 여러 곳에 적혀 있고 서로 어긋남.** allwinner-phoenix는
  `pubspec.yaml` 0.1.2, `Cargo.toml` 0.1.1, `about.dart` 0.1.0, 최신 태그
  v1.1.2가 모두 다릅니다. portside는 `about_dialog.dart`에
  `version = '0.1.7'`을 하드코딩했습니다.
- **태그와 pubspec 불일치.** 태그만 달고 pubspec을 올리지 않으면, 앱이
  보여주는 버전과 릴리스 이름이 달라집니다. dove-zip만 CI의
  `check-version` 잡으로 이를 막고 있습니다.
- **build number 규칙이 제각각.** portside는 patch+10, daylight와 dove는
  +1씩 증가, saturn은 수동입니다.

## 규칙

### 1. 버전의 원본은 `pubspec.yaml` 하나뿐

```yaml
version: 1.4.2+37
#        │ │ │  └ build number
#        └─┴─┴─── MAJOR.MINOR.PATCH (SemVer)
```

- 코드에서 버전이 필요하면 **`package_info_plus`로 읽습니다.** Dart 코드,
  `.iss` 기본값 등에 버전을 하드코딩하지 않습니다.
- `.iss`의 `MyAppVersion` 기본값은 CI가 덮어쓰므로 `0.0.0`으로 둡니다.
  "로컬 빌드임"이 한눈에 보이게 하기 위해서입니다.
- Rust 크레이트 등 다른 매니페스트가 함께 있는 앱은, 릴리스 커밋에서
  같은 버전으로 함께 올리고 CI 검사 대상에 포함합니다.

### 2. SemVer 해석

| 올리는 자리 | 언제 |
|---|---|
| MAJOR | 설정·데이터 호환이 깨지거나, 사용자가 다시 배워야 할 만큼 UI가 바뀔 때 |
| MINOR | 새 기능 |
| PATCH | 버그 수정만 |

`1.0.0` 이전(`0.y.z`)에는 MINOR를 호환이 깨지는 변경에 씁니다.
첫 공개 릴리스는 `0.1.0`입니다.

### 3. build number: 앱 전체에서 1씩만 증가, 되돌리지 않음

- 릴리스할 때마다 **+1** 합니다. MAJOR/MINOR가 올라가도 0으로 돌리지
  않습니다. Play Store `versionCode`, App Store `CFBundleVersion`,
  Windows `FileVersion`이 모두 단조 증가를 요구하기 때문입니다.
- portside의 patch+10 방식은 `0.2.0`이 되는 순간 번호가 줄어들므로 쓰지
  않습니다. 기존 번호는 그대로 두고 다음 릴리스부터 +1을 적용합니다.
- 모바일에서 같은 버전을 다시 올려야 할 때(스토어 거부 등)는 버전은 두고
  build number만 +1 합니다.

### 4. 프리릴리스

필요할 때만 씁니다.

```yaml
version: 1.5.0-rc.1+40
```

태그는 `v1.5.0-rc.1`이고, GitHub Release를 `--prerelease`로 만듭니다
([tagging.md](tagging.md)). 정식 버전은 `1.5.0+41`입니다.

### 5. 버전 올리기 절차

1. `pubspec.yaml`의 버전과 build number를 올립니다. 다른 매니페스트가
   있으면 같이 올립니다.
2. 커밋 메시지는 `chore(release): v1.4.2` 입니다.
3. PR로 `main`에 병합한 뒤, 병합 커밋에 태그를 답니다
   ([tagging.md](tagging.md)).

[`common/scripts/bump-version.sh`](../common/scripts/bump-version.sh)를 앱의
`scripts/`에 복사해 두면 1~2단계를 자동으로 합니다. 태그는 달지 않습니다.

```bash
scripts/bump-version.sh patch        # 1.4.2+37 -> 1.4.3+38
scripts/bump-version.sh minor        # 1.4.2+37 -> 1.5.0+38
scripts/bump-version.sh 1.5.0-rc.1   # 1.4.2+37 -> 1.5.0-rc.1+38
scripts/bump-version.sh build        # 1.4.2+37 -> 1.4.2+38 (스토어 재제출)
```

`Cargo.toml`이 있으면 같은 버전으로 함께 올립니다.
