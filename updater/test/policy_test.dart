import 'package:app_updater/app_updater.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('UpdatePolicy', () {
    late DateTime now;
    late UpdatePolicy policy;

    setUp(() {
      now = DateTime.utc(2026, 10, 10, 12);
      policy = UpdatePolicy(MemoryUpdateStateStore(), now: () => now);
    });

    test('due the first time, then not for 24 hours', () async {
      expect(await policy.isDue(), isTrue);
      await policy.markChecked();
      expect(await policy.isDue(), isFalse);
      now = now.add(const Duration(hours: 23, minutes: 59));
      expect(await policy.isDue(), isFalse);
      now = now.add(const Duration(minutes: 2));
      expect(await policy.isDue(), isTrue);
    });

    test('a clock set back does not silence checks forever', () async {
      await policy.markChecked();
      now = now.subtract(const Duration(days: 3));
      expect(await policy.isDue(), isTrue);
    });

    test('skipping remembers one version only', () async {
      expect(await policy.isSkipped('0.2.1'), isFalse);
      await policy.skip('0.2.1');
      expect(await policy.isSkipped('0.2.1'), isTrue);
      expect(await policy.isSkipped('0.2.2'), isFalse);
    });
  });

  group('checkAutomatically', () {
    late FakeServer server;
    late UpdatePolicy policy;

    setUp(() async {
      server = await FakeServer.start();
      policy = UpdatePolicy(MemoryUpdateStateStore());
    });
    tearDown(() => server.close());

    AppUpdater updater() => AppUpdater(
          server: server.serverUri, appId: 'app-flutter', currentVersion: '0.2.0', platform: mac);

    test('announces an update once, then waits for the interval', () async {
      server.updateBody = server.available();
      expect(await updater().checkAutomatically(policy), isA<UpdateAvailable>());
      expect(await updater().checkAutomatically(policy), isNull);
      expect(server.updateCalls, 1);
    });

    test('a failed check says nothing and is retried next start', () async {
      server.updateStatus = 500;
      expect(await updater().checkAutomatically(policy), isNull);
      expect(await policy.isDue(), isTrue);
      server.updateStatus = 200;
      server.updateBody = server.available();
      expect(await updater().checkAutomatically(policy), isA<UpdateAvailable>());
    });

    test('a skipped version is not announced, a newer one is', () async {
      await policy.skip('0.2.1');
      server.updateBody = server.available(latest: '0.2.1');
      expect(await updater().checkAutomatically(policy), isNull);

      final fresh = UpdatePolicy(MemoryUpdateStateStore());
      await fresh.skip('0.2.1');
      server.updateBody = server.available(latest: '0.2.2');
      expect(await updater().checkAutomatically(fresh), isA<UpdateAvailable>());
    });

    test('up to date is silent but counts as checked', () async {
      server.updateBody = {'updateAvailable': false, 'latest': '0.2.0'};
      expect(await updater().checkAutomatically(policy), isA<UpToDate>());
      expect(await policy.isDue(), isFalse);
    });
  });
}
