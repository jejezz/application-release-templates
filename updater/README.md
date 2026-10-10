# app_updater

릴리스 서버에 새 버전이 있는지 묻고, 설치 파일을 내려받아 **SHA-256 으로 검증**한 뒤 OS 설치기에 넘기는 순수 Dart 패키지입니다.
UI 도 Flutter 의존성도 없습니다 (대화상자 · 문구는 `common/lib/update/` 템플릿이 맡습니다).

설계: `introduce-public-repos` 저장소의 `docs/APP_UPDATER_DESIGN.md`. 서버 계약: 그 저장소 README 의 '업데이트 확인 API'.

```dart
final updater = AppUpdater(
  server: Uri.parse('https://c-a3f19c04.rtc.zoomon.art/repos'),
  appId: 'portside-flutter',      // AppIdentity.repositoryUrl 의 마지막 경로
  currentVersion: '0.2.0',        // package_info_plus 의 version
);

final r = await updater.check();  // UpToDate | UpdateAvailable | UpdateUnavailable | UpdateCheckFailed — 예외 없음
if (r is UpdateAvailable) {
  // 사용자가 동의한 뒤에만:
  final file = await updater.download(r.info, onProgress: (got, total) {});  // 크기 · SHA-256 검증
  await updater.install(file);                                                // OS 별 installer (다음 단계)
}
```

- `checkAutomatically(UpdatePolicy)` — 앱 시작용. 24시간에 한 번, 건너뛴 버전은 알리지 않고, 실패는 조용히 넘깁니다. 수동 "업데이트 확인" 은 `check()`.
- 서버는 `https` 만 (루프백 http 는 시험용). 다운로드 URL 은 `https://github.com/` 로 시작해야 합니다.
- 체크섬이 없으면 `UpdateUnavailable(noChecksum)` — **자동 설치 금지**, `releaseUrl` 만 안내합니다.

## 시험

```bash
dart pub get && dart analyze && dart test
dart run tool/live_check.dart https://<서버>/repos portside-flutter 0.1.0   # 실제 서버에 확인만 (다운로드 없음)
```

`test/vectors/version.json` 은 서버(`introduce-public-repos` 의 `test/vectors/version.json`)와 **같아야** 합니다.

## 상태

- ✅ 버전 비교 · `check` · `download` · 정책(`UpdatePolicy`) · OS 별 installer · 시험 42건
- ✅ UI 템플릿 (`common/lib/update/`) · ARB 문구 · 정보 창 / macOS 메뉴 연결 · 위젯 시험 (`../common/README.md` '업데이트' 절)
- ⬜ 실제 Windows · Linux 기기에서의 확인 (아래)

## 설치 (installer)

macOS 와 Windows 는 **내려받은 파일 자체가 설치 프로그램**이라, installer 는 파일을 OS 방식으로 열어 줄 뿐입니다. 압축을 풀어야 하는 Linux 만 코드가 있습니다.

| OS | `install()` 이 하는 일 | 결과 |
|---|---|---|
| macOS | `open <dmg>` — 사용자가 Applications 로 끌어다 놓음. 실행 중인 앱을 몰래 교체하지 않음 | `openedForUser` (앱은 계속 실행) |
| Windows | `explorer.exe <setup.exe>` — 셸이 열어서 UAC 를 띄움. `Process.start` 로 .exe 를 직접 띄우면 관리자 권한을 요구하는 설치 프로그램은 오류 740 으로 시작되지 않음. Inno 의 고정 `AppId` 로 제자리 업그레이드 | `installerStarted` (**앱은 곧 종료**) |
| Linux | tar.gz 를 풀어 **지금** 검증(폴더 하나 · `install.sh` 가 압축 안에 있음 · 앱 ID 는 `share/applications/<id>.desktop` 에서). 설치는 **앱이 종료된 뒤** 분리된 `sh` 가: 종료 대기 → `bash install.sh` (`~/.local`, 권한 불필요) → `gtk-launch <앱 ID>` → 임시 폴더 삭제 | `installerStarted` (**앱은 곧 종료**) |

- 프로세스 실행은 `CommandRunner` 로 주입합니다 (시험에서는 가짜). `platformInstaller(PlatformInfo.current())` 가 OS 에 맞는 것을 고릅니다.
- `AppUpdater(installer: …)` 를 **명시**해야 설치가 됩니다 (기본값 없음 — 시험이 실제로 파일을 열지 않게).
- Linux 의 설치 자체는 앱 종료 후라 실패해도 앱이 알릴 수 없습니다. 압축 해제 · 구조 검사까지는 종료 전에 오류로 알립니다.
- `AppUpdater.cleanUpOldDownloads()` — 시작할 때 부르면 하루 넘은 `app_updater_*` 임시 폴더를 지웁니다 (Windows 설치 프로그램은 자기 파일을 지우지 못함).

**macOS 에서 확인한 것:** 모든 시험 + Linux 헬퍼를 실제 `sh`/`bash` 로 실행(종료 대기 · 설치 · 재실행 호출 · 정리).
**아직 못 한 것:** 실제 Windows(UAC 와 `explorer.exe` 동작), 실제 Linux 데스크톱(`gtk-launch`).
