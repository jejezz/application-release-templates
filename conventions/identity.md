# 앱 정체성: 이름, 식별자, 게시자, 저작권

패키징·정보 창·라이선스 문서가 모두 여기 값을 가져다 씁니다. 지금 앱마다
가장 크게 흩어져 있는 부분이라 제일 먼저 확정해야 합니다.

## 현재 상태 (불일치)

| 앱 | bundle id 접두어 | 게시자 (Inno `AppPublisher`) | LICENSE 저작권자 | 플랫폼 파일 저작권자 |
|---|---|---|---|---|
| portside | `art.zoomon` | `jyahn` | Jong-yun Ahn | art.zoomon |
| daylight-commander | `art.zoomon` | `jyahn` | jyahn | jyahn |
| allwinner-phoenix | `art.zoomon` (Linux는 `com.example`) | `jyahn` | (LICENSE 없음) | jyahn |
| dove-zip | `com.ptype` | — | jyahn | com.ptype |
| MacBroom | `co.kr.ptype` → 미병합 브랜치에서 `art.zoomon` | — | Jongyun Ahn | co.kr.ptype |
| saturn-mobile | `com.europa` | — | (LICENSE 없음) | — |

같은 사람 이름이 `jyahn` / `Jong-yun Ahn` / `Jongyun Ahn` 세 가지로,
식별자 접두어가 `art.zoomon` / `com.ptype` / `co.kr.ptype` / `com.europa`
네 가지로 쓰이고 있습니다.

## 규칙

### 1. 게시 주체: 하나로 고정

모든 앱은 개인 앱이며 아래 값 하나만 씁니다.

| 항목 | 값 |
|---|---|
| 식별자 접두어 | `art.zoomon` |
| 게시자 (Inno `AppPublisher`, Windows `CompanyName`) | `Jongyun Ahn` |
| 저작권자 (LICENSE, 플랫폼 파일, 정보 창 공통) | `Jongyun Ahn` |
| 웹사이트 (`AppPublisherURL`, 정보 창 링크) | 별도 홍보 사이트가 없으므로 **각 앱의 GitHub 저장소 URL** |

- `jyahn`(핸들), `Jong-yun Ahn`(하이픈), `art.zoomon`(역도메인)을
  저작권자나 게시자 자리에 쓰지 않습니다. `art.zoomon`은 식별자에만 씁니다.
- `ptype-co-kr` 조직에 있는 저장소(saturn-mobile)도 개인 앱으로 보고 같은
  값을 씁니다.

### 2. 이름 표기 4종

| 용도 | 형식 | 예 | 쓰는 곳 |
|---|---|---|---|
| 표시 이름 | 띄어쓰기 있는 Title Case | `Dove Zip` | 창 제목, 정보 창, macOS `PRODUCT_NAME`, Windows `ProductName`, Inno `AppName`, 릴리스 제목 |
| 파일 이름 | 공백 없는 PascalCase | `DoveZip` | 릴리스 산출물, 설정 폴더 |
| 패키지 / 바이너리 | snake_case | `dove_zip` | `pubspec.yaml` `name:`, `BINARY_NAME` |
| 저장소 | kebab-case + `-flutter` | `dove-zip-flutter` | GitHub |

표시 이름은 **한 곳(macOS `AppInfo.xcconfig`의 `PRODUCT_NAME`)** 을 원본으로
삼고, CI는 거기서 읽습니다 (dove-zip이 이미 이렇게 합니다). `pubspec.yaml`의
`name:`은 snake_case라서 표시 이름으로 쓰면 안 됩니다.

### 3. 식별자

- 형식: `<접두어>.<패키지명에서 _ 뺀 소문자>`, 예: `art.zoomon.dovezip`
- macOS / iOS `PRODUCT_BUNDLE_IDENTIFIER`, Android `applicationId`,
  Linux `APPLICATION_ID`를 모두 **같은 값**으로 둡니다.
- 새 앱은 `flutter create --org <접두어> --project-name <패키지명>`으로
  만들어서 처음부터 맞춥니다. `com.example`이 남아 있으면 첫 릴리스 전에
  반드시 고칩니다.

### 4. 저작권 문자열 (한 가지 형식)

```
Copyright © <첫 릴리스 연도> <저작권자>
```

`All rights reserved.`는 MIT 라이선스와 맞지 않으므로 붙이지 않습니다.

| 위치 | 필드 |
|---|---|
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_COPYRIGHT` |
| `windows/runner/Runner.rc` | `LegalCopyright`, `CompanyName`(= 게시자) |
| `LICENSE` | `Copyright (c) <연도> <저작권자>` (MIT 원문 형식) |
| 정보 창 | [about-dialog.md](about-dialog.md) |
| Inno Setup | `AppPublisher`(= 게시자), `AppCopyright` |

### 5. 한 번 릴리스한 뒤에는 바꾸지 않는 값

- bundle id / applicationId: 바꾸면 스토어와 macOS에서 다른 앱이 되고,
  기존 설정 파일도 이어지지 않습니다.
- Windows Inno Setup `AppId` GUID: 바꾸면 업그레이드와 제거가 깨집니다.
- 이미 릴리스된 앱(dove-zip의 `com.ptype.doveZip`, saturn의
  `com.europa.rtc.mobile`, MacBroom의 `co.kr.ptype.macbroom`)은 식별자를
  그대로 두고 **저작권자와 게시자 표시만** 새 규칙으로 맞춥니다.
  MacBroom은 미병합 브랜치에서 이미 `art.zoomon`으로 바꿨으므로, 그
  브랜치를 병합할지는 기존 설치 사용자에게 설정이 이어지지 않는다는 점을
  감수할지에 달려 있습니다.

### 6. 설정 저장 위치

`shared_preferences`를 쓰지 않고 파일로 저장할 때는 폴더 이름에 **파일
이름**(PascalCase)을 씁니다.

- macOS: `~/Library/Application Support/<FileName>`
- Windows: `%APPDATA%\<FileName>`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/<FileName>`
