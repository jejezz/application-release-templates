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
회사 표기가 `art.zoomon` / `com.ptype` / `co.kr.ptype` 세 가지로 쓰이고
있습니다.

## 규칙

### 1. 게시 주체(프로필)를 앱마다 하나 고른다

🟡 **결정 필요** — 아래 값은 제안입니다. 프로필 수와 각 값을 확정해 주세요.

| 항목 | 개인 프로필 (제안) | 회사 프로필 (제안) |
|---|---|---|
| 사용처 | `jejezz/*` 저장소의 개인 앱 | `ptype-co-kr/*` 저장소의 업무 앱 |
| 식별자 접두어 | `art.zoomon` | `kr.co.ptype` |
| 게시자 표시 (`Publisher`) | `zoomon.art` | `PTYPE Co., Ltd.` |
| 저작권자 (LICENSE, 플랫폼 파일, 정보 창 공통) | `Jongyun Ahn` | `PTYPE Co., Ltd.` |
| 웹사이트 | `https://github.com/jejezz` | 회사 URL |

제안 근거:
- `art.zoomon`은 이미 portside·daylight·allwinner에서 쓰고 있고, portside와
  MacBroom은 일부러 이 값으로 바꿨습니다 ("Rebrand bundle ID and company
  name to art.zoomon").
- 식별자 접두어는 **실제 도메인을 뒤집은 형태**여야 합니다.
  `ptype.co.kr`을 뒤집으면 `kr.co.ptype`이고, 지금 쓰는 `com.ptype`,
  `co.kr.ptype`은 둘 다 뒤집기가 틀렸습니다. 다만 이미 릴리스된 앱의
  bundle id는 바꾸지 않습니다 (아래 5번).
- 저작권자에는 법적 주체의 이름을 씁니다. 핸들(`jyahn`)이나 역도메인
  (`com.ptype`)은 쓰지 않습니다.

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
- 이미 릴리스된 앱(dove-zip의 `com.ptype.doveZip` 등)은 식별자를 그대로
  두고 **저작권자와 게시자 표시만** 새 규칙으로 맞춥니다.

### 6. 설정 저장 위치

`shared_preferences`를 쓰지 않고 파일로 저장할 때는 폴더 이름에 **파일
이름**(PascalCase)을 씁니다.

- macOS: `~/Library/Application Support/<FileName>`
- Windows: `%APPDATA%\<FileName>`
- Linux: `${XDG_CONFIG_HOME:-~/.config}/<FileName>`
