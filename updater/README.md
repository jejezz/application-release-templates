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

- ✅ 버전 비교 · `check` · `download` · 정책(`UpdatePolicy`) · 시험 31건
- ⬜ OS 별 installer (macOS DMG 열기 · Windows · Linux) — `UpdateInstaller` 인터페이스만 있음
- ⬜ UI 템플릿 (`common/lib/update/`) · ARB 문구
