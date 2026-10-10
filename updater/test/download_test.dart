import 'dart:convert';
import 'dart:io';

import 'package:app_updater/app_updater.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late FakeServer server;
  late Directory tmp;

  setUp(() async {
    server = await FakeServer.start();
    tmp = await Directory.systemTemp.createTemp('app_updater_test_');
  });
  tearDown(() async {
    await server.close();
    await tmp.delete(recursive: true);
  });

  AppUpdater updater({List<String>? prefixes}) => AppUpdater(
        server: server.serverUri,
        appId: 'app-flutter',
        currentVersion: '0.2.0',
        platform: mac,
        downloadUrlPrefixes: prefixes ?? server.prefixes,
        tempRoot: tmp,
        requestTimeout: const Duration(seconds: 2),
      );

  Future<UpdateInfo> info([Map<String, Object?>? body]) async {
    server.updateBody = body ?? server.available();
    final r = await updater().check();
    return (r as UpdateAvailable).info;
  }

  Future<UpdateErrorKind> failure(Future<Object?> f) async {
    try {
      await f;
    } on UpdateException catch (e) {
      return e.kind;
    }
    fail('expected an UpdateException');
  }

  int leftovers() => tmp.listSync().length;

  test('downloads, reports progress, verifies, keeps the right file name', () async {
    final bytes = List<int>.generate(300000, (i) => i % 251);
    final i = await info(server.available(bytes: bytes));
    final progress = <int>[];
    final d = await updater().download(i, onProgress: (got, total) {
      expect(total, bytes.length);
      progress.add(got);
    });
    expect(d.file.path.endsWith('App-0.2.1-macos-universal.dmg'), isTrue);
    expect(await d.file.readAsBytes(), bytes);
    expect(progress.last, bytes.length);
    expect(progress, orderedEquals([...progress]..sort()));
    expect(File('${d.file.path}.part').existsSync(), isFalse);
    await updater().discard(d);
    expect(leftovers(), 0);
  });

  test('a wrong checksum is refused and nothing is left behind', () async {
    final i = await info(server.available(sha256Hex: sha256.convert(utf8.encode('other')).toString()));
    expect(await failure(updater().download(i)), UpdateErrorKind.checksumMismatch);
    expect(leftovers(), 0);
  });

  test('size mismatch, both shorter and longer than announced', () async {
    var i = await info(server.available(size: 999999));
    expect(await failure(updater().download(i)), UpdateErrorKind.sizeMismatch);
    final data = utf8.encode('pretend dmg contents');
    i = await info(server.available(size: data.length - 3));
    expect(await failure(updater().download(i)), UpdateErrorKind.sizeMismatch);
    expect(leftovers(), 0);
  });

  test('refuses a URL outside the allowed prefixes without touching the network', () async {
    final i = await info();
    expect(await failure(updater(prefixes: ['https://github.com/']).download(i)), UpdateErrorKind.insecureUrl);
    expect(server.fileCalls, 0);
    expect(leftovers(), 0);
  });

  test('refuses file names that could escape the temp directory', () async {
    for (final name in ['../evil.dmg', 'a/b.dmg', '.hidden', r'..\evil.exe', 'bad\nname']) {
      final i = UpdateInfo(
        appId: 'app-flutter',
        currentVersion: '0.2.0',
        latestVersion: '0.2.1',
        tag: 'v0.2.1',
        notes: '',
        asset: UpdateAsset(name: name, url: Uri.parse('${server.origin}/dl/x'), size: 1, sha256: 'a' * 64),
      );
      expect(await failure(updater().download(i)), UpdateErrorKind.badResponse, reason: name);
    }
    expect(server.fileCalls, 0);
  });

  test('HTTP errors from the file host', () async {
    final i = await info();
    server.files.clear();
    expect(await failure(updater().download(i)), UpdateErrorKind.server);
    expect(leftovers(), 0);
  });

  test('a stalled connection times out instead of hanging', () async {
    final i = await info(server.available(bytes: List<int>.filled(5000, 1)));
    server.stallAfter = 1000;
    expect(await failure(updater().download(i)), UpdateErrorKind.network);
    server.stall?.complete();
    expect(leftovers(), 0);
  });

  test('cancel stops the download and cleans up', () async {
    final i = await info(server.available(bytes: List<int>.filled(2 * 1024 * 1024, 7)));
    final token = CancelToken();
    final kind = await failure(updater().download(i, cancel: token, onProgress: (_, __) => token.cancel()));
    expect(kind, UpdateErrorKind.cancelled);
    expect(leftovers(), 0);
  });

  test('install without an installer is a clear error', () async {
    final i = await info();
    final d = await updater().download(i);
    expect(await failure(updater().install(d)), UpdateErrorKind.unsupportedPlatform);
  });

  test('install hands the verified file to the installer', () async {
    final fake = _FakeInstaller();
    final u = AppUpdater(
      server: server.serverUri, appId: 'app-flutter', currentVersion: '0.2.0',
      platform: mac, downloadUrlPrefixes: server.prefixes, tempRoot: tmp, installer: fake,
    );
    server.updateBody = server.available();
    final d = await u.download(((await u.check()) as UpdateAvailable).info);
    expect(await u.install(d), InstallOutcome.openedForUser);
    expect(fake.got?.file.path, d.file.path);
  });
}

class _FakeInstaller implements UpdateInstaller {
  DownloadedUpdate? got;

  @override
  Future<InstallOutcome> install(DownloadedUpdate update) async {
    got = update;
    return InstallOutcome.openedForUser;
  }
}
