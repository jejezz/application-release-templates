# 라이선스 규칙

## 현재 상태

- LICENSE 파일: allwinner와 saturn에는 없습니다. 나머지는 MIT이지만
  저작권자 이름이 `jyahn` / `Jong-yun Ahn` / `Jongyun Ahn`으로 다릅니다.
- 오픈소스 라이선스 화면(`LicensePage`): 어느 앱에도 없습니다.
- 에셋 저작자 표시: 모든 앱이 Icons8 아이콘과 SeoulNamsan 폰트를
  쓰는데, 저작자 표시를 한 곳은 allwinner의 Icons8 한 건뿐입니다.
- portside의 README에 libserialport(LGPL v3) 사용이 적혀 있습니다.

## 규칙

### 1. 앱 자체 라이선스

| 저장소 | 라이선스 | LICENSE 파일 |
|---|---|---|
| 공개 저장소 (`jejezz/*` 개인 앱) | **MIT** | 필수 |
| 비공개 / 업무 앱 (`ptype-co-kr/*`) | 비공개(Proprietary) | 필수. 한 줄이면 됩니다: `Copyright © <연도> <저작권자>. All rights reserved. 무단 복제·배포 금지.` |

MIT LICENSE는 원문 그대로 쓰고 첫 줄만 바꿉니다.

```
MIT License

Copyright (c) 2026 Jongyun Ahn
...
```

- 저작권자는 [identity.md](identity.md)의 값이고, 연도는 첫 릴리스
  연도입니다.
- README 끝에는 `## 라이선스` 절을 두고 `[MIT](LICENSE)`로 링크합니다.
  서드파티 중 주의가 필요한 라이선스(아래 3번)도 여기에 적습니다.

### 2. 오픈소스 라이선스 화면

- 모든 앱의 정보 창에 `showLicensePage` 버튼을 둡니다
  ([about-dialog.md](about-dialog.md)). Flutter가 pub 패키지 라이선스를
  자동으로 모아 보여줍니다.
- pub 패키지가 아닌 에셋과 네이티브 라이브러리는 `main()`에서 직접
  등록합니다.

```dart
void registerExtraLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['SeoulNamsan'],
      await rootBundle.loadString('assets/licenses/seoul-namsan.txt'),
    );
  });
  // Icons8, libserialport 등도 같은 방식
}
```

라이선스 원문 파일은 `assets/licenses/`에 둡니다.

### 3. 에셋과 네이티브 라이브러리

| 대상 | 조건 | 해야 할 것 |
|---|---|---|
| **Icons8** (무료 플랜) | 저작자 표시와 링크 필수 | 정보 창에 `앱 아이콘: Icons8 (icons8.com)` 한 줄 + README 크레딧. 유료 플랜이면 표시 의무 없음 🟡 (플랜 확인 필요) |
| **SeoulNamsan 폰트** (서울시) | 무료 사용 가능, 폰트 파일 단독 판매 금지 | 라이선스 등록(위 2번), README 크레딧 |
| **LGPL 라이브러리** (예: libserialport) | 사용자가 라이브러리를 교체할 수 있어야 함 → **동적 링크** 유지 | 정적 링크 금지. README와 오픈소스 라이선스 화면에 명시 |
| **GPL** | 앱 전체에 GPL 적용 | 사용하지 않습니다 |

새 의존성을 추가할 때 라이선스가 MIT, BSD, Apache-2.0, Zlib, OFL이 아니면
PR 설명에 그 이유를 적습니다.

### 4. 설치 프로그램 EULA

MIT 앱은 설치 프로그램에 라이선스 동의 화면을 넣지 않습니다
(`LicenseFile` 지시어를 쓰지 않음). 사용자에게 동의를 받을 조건이 없으니
단계만 늘어납니다. 비공개 앱이 배포 조건을 명시해야 할 때만 넣습니다.
