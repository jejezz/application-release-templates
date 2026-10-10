import 'dart:io';

import 'package:app_updater/app_updater.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _Call {
  _Call(this.kind, this.exe, this.args);
  final String kind; // run | detached
  final String exe;
  final List<String> args;
}

/// Records commands. `run` can be forwarded to the real thing for `tar`.
class _Runner implements CommandRunner {
  _Runner({this.exitCode = 0, this.realTar = false});

  final int exitCode;
  final bool realTar;
  final calls = <_Call>[];

  @override
  Future<int> run(String executable, List<String> arguments) async {
    calls.add(_Call('run', executable, arguments));
    if (realTar && executable == 'tar') {
      return (await Process.run('tar', arguments)).exitCode;
    }
    return exitCode;
  }

  @override
  Future<void> startDetached(String executable, List<String> arguments) async {
    calls.add(_Call('detached', executable, arguments));
  }
}

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('installers_test_'));
  tearDown(() => tmp.delete(recursive: true));

  UpdateInfo info(String name) => UpdateInfo(
        appId: 'a', currentVersion: '1.0.0', latestVersion: '1.1.0', tag: 'v1.1.0', notes: '',
        asset: UpdateAsset(name: name, url: Uri.parse('https://github.com/x'), size: 1, sha256: 'a' * 64),
      );

  DownloadedUpdate downloaded(String name, [List<int> bytes = const [1]]) {
    final dir = Directory(p.join(tmp.path, 'app_updater_x'))..createSync();
    final f = File(p.join(dir.path, name))..writeAsBytesSync(bytes);
    return DownloadedUpdate(info: info(name), file: f);
  }

  Future<UpdateErrorKind> failure(Future<Object?> f) async {
    try {
      await f;
    } on UpdateException catch (e) {
      return e.kind;
    }
    fail('expected an UpdateException');
  }

  group('macOS', () {
    test('opens the DMG and leaves the app running', () async {
      final r = _Runner();
      final d = downloaded('App-1.1.0-macos-universal.dmg');
      expect(await MacosInstaller(runner: r).install(d), InstallOutcome.openedForUser);
      expect(r.calls.single.exe, 'open');
      expect(r.calls.single.args, [d.file.path]);
    });

    test('a failing open is an error', () async {
      final d = downloaded('App-1.1.0-macos-universal.dmg');
      expect(await failure(MacosInstaller(runner: _Runner(exitCode: 1)).install(d)), UpdateErrorKind.installFailed);
    });
  });

  group('Windows', () {
    test('opens the setup through the shell so UAC can prompt', () async {
      final r = _Runner();
      final d = downloaded('App-1.1.0-windows-x64-setup.exe');
      expect(await WindowsInstaller(runner: r).install(d), InstallOutcome.installerStarted);
      expect(r.calls.single.kind, 'detached');
      expect(r.calls.single.exe, 'explorer.exe');
      expect(r.calls.single.args, [d.file.path]);
    });
  });

  group('Linux', skip: Platform.isWindows ? 'needs tar and sh' : null, () {
    /// Builds App/{install.sh,share/applications/<id>.desktop,bin/app} as a tar.gz.
    Future<DownloadedUpdate> tarball({String top = 'App', bool installSh = true, String desktop = 'art.zoomon.app.desktop', int extraTops = 0}) async {
      final src = Directory(p.join(tmp.path, 'src'))..createSync();
      final root = Directory(p.join(src.path, top))..createSync();
      if (installSh) File(p.join(root.path, 'install.sh')).writeAsStringSync('#!/usr/bin/env bash\nexit 0\n');
      Directory(p.join(root.path, 'share', 'applications')).createSync(recursive: true);
      if (desktop.isNotEmpty) File(p.join(root.path, 'share', 'applications', desktop)).writeAsStringSync('[Desktop Entry]\n');
      File(p.join(root.path, 'app')).writeAsStringSync('binary');
      for (var i = 0; i < extraTops; i++) {
        final other = Directory(p.join(src.path, 'Other$i'))..createSync();
        File(p.join(other.path, 'install.sh')).writeAsStringSync('exit 0\n');
      }
      final dir = Directory(p.join(tmp.path, 'app_updater_x'))..createSync();
      final archive = p.join(dir.path, 'App-1.1.0-linux-x64.tar.gz');
      final code = (await Process.run('tar', ['-czf', archive, '-C', src.path, '.'])).exitCode;
      expect(code, 0);
      return DownloadedUpdate(info: info('App-1.1.0-linux-x64.tar.gz'), file: File(archive));
    }

    test('unpacks, then installs and relaunches after this app exits', () async {
      final r = _Runner(realTar: true);
      final d = await tarball();
      expect(await LinuxInstaller(runner: r, currentPid: 4242).install(d), InstallOutcome.installerStarted);

      final start = r.calls.last;
      expect(start.kind, 'detached');
      expect(start.exe, 'sh');
      expect(start.args[0], '-c');
      expect(start.args[1], contains('kill -0 "\$1"')); // waits for the app
      expect(start.args[1], contains('bash "\$2"')); // runs install.sh after that
      expect(start.args.sublist(3, 5), ['4242', endsWith('/App/install.sh')]);
      expect(File(start.args[4]).existsSync(), isTrue);
      expect(start.args[5], 'art.zoomon.app'); // from share/applications/<id>.desktop
      expect(start.args[6], d.directory.path); // removed when done
      expect(start.args.length, 7);
    });

    test('the helper really waits, installs, relaunches and cleans up', () async {
      final r = _Runner(realTar: true);
      final marker = File(p.join(tmp.path, 'marker.txt'));
      final launched = File(p.join(tmp.path, 'launched.txt'));
      final d = await tarball();
      // Replace the harmless install.sh in the unpacked copy's source: re-pack with one that leaves a mark.
      File(p.join(tmp.path, 'src', 'App', 'install.sh')).writeAsStringSync('#!/usr/bin/env bash\necho installed > "${marker.path}"\n');
      final archive = d.file.path;
      expect((await Process.run('tar', ['-czf', archive, '-C', p.join(tmp.path, 'src'), '.'])).exitCode, 0);

      // A stand-in for the running app that exits after a moment, and a fake gtk-launch.
      final app = await Process.start('sleep', ['1']);
      await LinuxInstaller(runner: r, currentPid: app.pid).install(d);
      final bin = Directory(p.join(tmp.path, 'bin'))..createSync();
      final fake = File(p.join(bin.path, 'gtk-launch'))
        ..writeAsStringSync('#!/bin/sh\necho "\$1" > "${launched.path}"\n');
      await Process.run('chmod', ['+x', fake.path]);

      final start = r.calls.last;
      final started = DateTime.now();
      final res = await Process.run(start.exe, start.args, environment: {'PATH': '${bin.path}:${Platform.environment['PATH']}'});
      expect(res.exitCode, 0, reason: '${res.stderr}');
      // It had to wait for the stand-in app (about a second) before installing.
      expect(DateTime.now().difference(started), greaterThan(const Duration(milliseconds: 500)));
      expect(marker.existsSync(), isTrue, reason: 'install.sh ran');
      expect(launched.readAsStringSync().trim(), 'art.zoomon.app');
      expect(d.directory.existsSync(), isFalse, reason: 'temp folder removed');
      await app.exitCode;
    });

    test('no .desktop file → installs but cannot relaunch (empty app id)', () async {
      final r = _Runner(realTar: true);
      final d = await tarball(desktop: '');
      await LinuxInstaller(runner: r).install(d);
      expect(r.calls.last.args[5], '');
    });

    test('a broken archive is reported before the app quits', () async {
      final d = downloaded('App-1.1.0-linux-x64.tar.gz', [1, 2, 3]);
      expect(await failure(LinuxInstaller(runner: _Runner(realTar: true)).install(d)), UpdateErrorKind.installFailed);
    });

    test('needs exactly one folder with install.sh', () async {
      expect(await failure(LinuxInstaller(runner: _Runner(realTar: true)).install(await tarball(installSh: false))), UpdateErrorKind.installFailed);
      tmp.listSync().forEach((e) => e.deleteSync(recursive: true));
      expect(await failure(LinuxInstaller(runner: _Runner(realTar: true)).install(await tarball(extraTops: 1))), UpdateErrorKind.installFailed);
    });

    test('an install.sh symlinked outside the archive is refused', () async {
      final outside = File(p.join(tmp.path, 'outside.sh'))..writeAsStringSync('exit 0\n');
      final src = Directory(p.join(tmp.path, 'src', 'App'))..createSync(recursive: true);
      Link(p.join(src.path, 'install.sh')).createSync(outside.path);
      final dir = Directory(p.join(tmp.path, 'app_updater_x'))..createSync();
      final archive = p.join(dir.path, 'App-1.1.0-linux-x64.tar.gz');
      expect((await Process.run('tar', ['-czf', archive, '-C', p.join(tmp.path, 'src'), '.'])).exitCode, 0);
      final d = DownloadedUpdate(info: info('App-1.1.0-linux-x64.tar.gz'), file: File(archive));
      expect(await failure(LinuxInstaller(runner: _Runner(realTar: true)).install(d)), UpdateErrorKind.installFailed);
    });
  });

  group('platformInstaller / cleanup', () {
    test('picks by OS', () {
      expect(platformInstaller(const PlatformInfo(os: 'macos', arch: 'arm64')), isA<MacosInstaller>());
      expect(platformInstaller(const PlatformInfo(os: 'windows', arch: 'x64')), isA<WindowsInstaller>());
      expect(platformInstaller(const PlatformInfo(os: 'linux', arch: 'x64')), isA<LinuxInstaller>());
      expect(() => platformInstaller(const PlatformInfo(os: 'freebsd', arch: 'x64')), throwsA(isA<UpdateException>()));
    });

    test('cleanUpOldDownloads removes only old app_updater_ folders', () async {
      final old = Directory(p.join(tmp.path, 'app_updater_old'))..createSync();
      final fresh = Directory(p.join(tmp.path, 'app_updater_fresh'))..createSync();
      final other = Directory(p.join(tmp.path, 'something_else'))..createSync();
      // Age `old` by two days.
      await Process.run('touch', ['-t', '200001010000', old.path]);
      final u = AppUpdater(
        server: Uri.parse('https://example.com/repos'), appId: 'a', currentVersion: '1.0.0',
        platform: const PlatformInfo(os: 'macos', arch: 'arm64'), tempRoot: tmp,
      );
      await u.cleanUpOldDownloads();
      expect(old.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
      expect(other.existsSync(), isTrue);
    });
  });
}
