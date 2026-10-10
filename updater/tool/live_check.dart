// 실제 서버에 업데이트 확인만 해 본다 (다운로드 없음).
//   dart run tool/live_check.dart <서버 URL> <앱 id> <현재 버전>
import 'package:app_updater/app_updater.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    print('usage: dart run tool/live_check.dart <server> <app-id> <version>');
    return;
  }
  final updater = AppUpdater(server: Uri.parse(args[0]), appId: args[1], currentVersion: args[2]);
  final r = await updater.check();
  switch (r) {
    case UpdateAvailable(:final info):
      print('available: ${info.currentVersion} -> ${info.latestVersion}');
      print('  file   : ${info.asset.name} (${info.asset.size} bytes)');
      print('  sha256 : ${info.asset.sha256}');
    case UpdateUnavailable(:final reason, :final latestVersion, :final releaseUrl):
      print('newer $latestVersion exists but cannot be installed automatically: ${reason.name} ($releaseUrl)');
    case UpToDate(:final latestVersion):
      print('up to date (latest: $latestVersion)');
    case UpdateCheckFailed(:final error):
      print('failed: $error');
  }
  updater.close();
}
