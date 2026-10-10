import 'package:app_updater/app_updater.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late FakeServer server;

  setUp(() async => server = await FakeServer.start());
  tearDown(() => server.close());

  AppUpdater updater({String version = '0.2.0', Uri? uri}) => AppUpdater(
        server: uri ?? server.serverUri,
        appId: 'app-flutter',
        currentVersion: version,
        platform: mac,
      );

  test('asks with app, version, os and arch', () async {
    server.updateBody = server.available();
    await updater(version: '0.2.0+7').check();
    expect(server.lastQuery,
        {'app': 'app-flutter', 'version': '0.2.0', 'os': 'macos', 'arch': 'arm64'});
  });

  test('a newer version with a checksum is available', () async {
    server.updateBody = server.available();
    final r = await updater().check();
    expect(r, isA<UpdateAvailable>());
    final info = (r as UpdateAvailable).info;
    expect(info.latestVersion, '0.2.1');
    expect(info.asset.name, 'App-0.2.1-macos-universal.dmg');
    expect(info.asset.sha256, hasLength(64));
    expect(info.releaseUrl.toString(), startsWith('https://github.com/'));
  });

  test('server says no update → UpToDate', () async {
    server.updateBody = {'app': 'app-flutter', 'current': '0.2.1', 'updateAvailable': false, 'latest': '0.2.1'};
    final r = await updater(version: '0.2.1').check();
    expect(r, isA<UpToDate>());
    expect((r as UpToDate).latestVersion, '0.2.1');
  });

  test('never goes backwards even if the server claims an update', () async {
    server.updateBody = server.available(latest: '0.2.1');
    expect(await updater(version: '0.3.0').check(), isA<UpToDate>());
    expect(await updater(version: '0.2.1+9').check(), isA<UpToDate>());
  });

  test('no checksum → UpdateUnavailable(noChecksum), never installable', () async {
    server.updateBody = server.available(reason: 'no-checksum', sha256Hex: 'ignored');
    var r = await updater().check();
    expect(r, isA<UpdateUnavailable>());
    expect((r as UpdateUnavailable).reason, UnavailableReason.noChecksum);

    final body = server.available();
    final asset = Map<String, Object?>.of(body['asset']! as Map<String, Object?>);
    body['asset'] = {...asset, 'sha256': null};
    server.updateBody = body;
    r = await updater().check();
    expect((r as UpdateUnavailable).reason, UnavailableReason.noChecksum);

    body['asset'] = {...asset, 'sha256': 'not-hex'};
    r = await updater().check();
    expect((r as UpdateUnavailable).reason, UnavailableReason.noChecksum);
  });

  test('no file for this platform → UpdateUnavailable(noAssetForPlatform)', () async {
    server.updateBody = {
      'updateAvailable': true,
      'latest': '0.2.1',
      'releaseUrl': 'https://github.com/jejezz/app-flutter/releases/tag/v0.2.1',
      'asset': null,
      'reason': 'no-asset-for-platform',
    };
    final r = await updater().check();
    expect((r as UpdateUnavailable).reason, UnavailableReason.noAssetForPlatform);
    expect(r.releaseUrl, isNotNull);
  });

  test('failures are results, not exceptions', () async {
    Future<UpdateErrorKind> kind() async =>
        ((await updater().check()) as UpdateCheckFailed).error.kind;

    server.updateStatus = 404;
    expect(await kind(), UpdateErrorKind.unknownApp);
    server.updateStatus = 500;
    expect(await kind(), UpdateErrorKind.server);
    server.updateStatus = 200;
    server.rawUpdateBody = '<html>not json';
    expect(await kind(), UpdateErrorKind.badResponse);
    server.rawUpdateBody = '[1,2]';
    expect(await kind(), UpdateErrorKind.badResponse);
    server.rawUpdateBody = '{"updateAvailable":"yes"}';
    expect(await kind(), UpdateErrorKind.badResponse);
    server.rawUpdateBody = null;
    server.updateBody = {'updateAvailable': true, 'latest': 'nightly'};
    expect(await kind(), UpdateErrorKind.badResponse);

    final dead = server.serverUri;
    await server.close();
    final r = await updater(uri: dead).check();
    expect((r as UpdateCheckFailed).error.kind, UpdateErrorKind.network);
    server = await FakeServer.start(); // for tearDown
  });

  test('a download URL that is not https is dropped from the response', () async {
    final body = server.available();
    body['asset'] = {...(body['asset']! as Map<String, Object?>), 'url': 'http://evil.example/x.dmg'};
    server.updateBody = body;
    final r = await updater().check();
    expect((r as UpdateCheckFailed).error.kind, UpdateErrorKind.badResponse);
  });

  group('construction', () {
    test('the server must be https (loopback http is allowed for tests)', () {
      expect(
        () => AppUpdater(server: Uri.parse('http://example.com/repos'), appId: 'a', currentVersion: '1.0.0', platform: mac),
        throwsA(isA<UpdateException>().having((e) => e.kind, 'kind', UpdateErrorKind.insecureUrl)),
      );
      expect(
        () => AppUpdater(server: Uri.parse('https://example.com/repos'), appId: 'a', currentVersion: '1.0.0', platform: mac),
        returnsNormally,
      );
    });

    test('bad version or app id', () {
      expect(() => AppUpdater(server: server.serverUri, appId: 'a', currentVersion: 'dev', platform: mac), throwsArgumentError);
      expect(() => AppUpdater(server: server.serverUri, appId: '../x', currentVersion: '1.0.0', platform: mac), throwsArgumentError);
    });
  });
}
