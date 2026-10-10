import 'dart:io';

import 'package:path/path.dart' as p;

import 'errors.dart';
import 'installer.dart';
import 'platform.dart';

/// Runs OS commands. Faked in tests so nothing real is opened or installed.
abstract interface class CommandRunner {
  /// Runs to completion and returns the exit code.
  Future<int> run(String executable, List<String> arguments);

  /// Starts a process that keeps running after this app exits.
  Future<void> startDetached(String executable, List<String> arguments);
}

final class SystemCommandRunner implements CommandRunner {
  const SystemCommandRunner();

  @override
  Future<int> run(String executable, List<String> arguments) async {
    try {
      return (await Process.run(executable, arguments)).exitCode;
    } on ProcessException catch (e) {
      throw UpdateException(UpdateErrorKind.installFailed, 'Could not run $executable: ${e.message}', cause: e);
    }
  }

  @override
  Future<void> startDetached(String executable, List<String> arguments) async {
    try {
      await Process.start(executable, arguments, mode: ProcessStartMode.detached);
    } on ProcessException catch (e) {
      throw UpdateException(UpdateErrorKind.installFailed, 'Could not start $executable: ${e.message}', cause: e);
    }
  }
}

/// The installer for [platform]. macOS and Windows installers are the
/// downloaded file itself (a DMG, a setup.exe), so "installing" is opening it
/// the way the OS opens it; only Linux's tarball needs unpacking.
UpdateInstaller platformInstaller(PlatformInfo platform, {CommandRunner runner = const SystemCommandRunner()}) =>
    switch (platform.os) {
      'macos' => MacosInstaller(runner: runner),
      'windows' => WindowsInstaller(runner: runner),
      'linux' => LinuxInstaller(runner: runner),
      final other => throw UpdateException(UpdateErrorKind.unsupportedPlatform, 'No installer for $other'),
    };

/// Opens the DMG. The person drags the app to Applications, as with a manual
/// install; a running app is not replaced behind its back.
final class MacosInstaller implements UpdateInstaller {
  const MacosInstaller({this.runner = const SystemCommandRunner()});

  final CommandRunner runner;

  @override
  Future<InstallOutcome> install(DownloadedUpdate update) async {
    final code = await runner.run('open', [update.file.path]);
    if (code != 0) {
      throw UpdateException(UpdateErrorKind.installFailed, '"open" exited with $code');
    }
    return InstallOutcome.openedForUser;
  }
}

/// Opens the Inno Setup installer. Done through the shell (explorer) rather
/// than by starting the .exe directly: the installer asks for administrator
/// rights, and CreateProcess refuses to start such a file from a normal
/// process (error 740) while the shell shows the UAC prompt. Inno's fixed
/// AppId makes this an in-place upgrade.
final class WindowsInstaller implements UpdateInstaller {
  const WindowsInstaller({this.runner = const SystemCommandRunner()});

  final CommandRunner runner;

  @override
  Future<InstallOutcome> install(DownloadedUpdate update) async {
    await runner.startDetached('explorer.exe', [update.file.path]);
    return InstallOutcome.installerStarted;
  }
}

/// Unpacks the tarball and runs its install.sh (installs under ~/.local, no
/// root needed) *after this app has exited*, then starts the app again.
///
/// Everything that can be checked is checked before returning, while the app
/// is still running and can show an error: the archive unpacks, it holds one
/// top-level folder with an install.sh that really is inside the unpacked
/// tree. Only the install itself happens after exit.
final class LinuxInstaller implements UpdateInstaller {
  const LinuxInstaller({
    this.runner = const SystemCommandRunner(),
    this.currentPid,
  });

  final CommandRunner runner;

  /// This process's id, which the helper waits to exit. Defaults to [pid].
  final int? currentPid;

  // $1 = pid to wait for, $2 = install.sh, $3 = application id (may be empty), $4 = temp dir to remove.
  static const _helper = r'''
n=0
while kill -0 "$1" 2>/dev/null && [ "$n" -lt 150 ]; do sleep 0.2; n=$((n+1)); done
if bash "$2" >/dev/null 2>&1; then
  if [ -n "$3" ]; then gtk-launch "$3" >/dev/null 2>&1; fi
fi
rm -rf "$4"
''';

  @override
  Future<InstallOutcome> install(DownloadedUpdate update) async {
    final out = Directory(p.join(update.directory.path, 'unpacked'))..createSync();
    final code = await runner.run('tar', ['-xzf', update.file.path, '-C', out.path]);
    if (code != 0) {
      throw UpdateException(UpdateErrorKind.installFailed, 'Could not unpack ${p.basename(update.file.path)} (tar exit $code)');
    }

    final tops = [
      for (final e in out.listSync(followLinks: false))
        if (e is Directory && File(p.join(e.path, 'install.sh')).existsSync()) e,
    ];
    if (tops.length != 1) {
      throw UpdateException(UpdateErrorKind.installFailed, 'The archive does not hold exactly one folder with an install.sh');
    }
    final top = tops.single;
    final script = File(p.join(top.path, 'install.sh'));
    final resolved = script.resolveSymbolicLinksSync();
    if (!p.isWithin(out.resolveSymbolicLinksSync(), resolved)) {
      throw UpdateException(UpdateErrorKind.installFailed, 'install.sh points outside the archive');
    }

    // The .desktop file is named after the application id (conventions/packaging.md §4).
    final desktops = Directory(p.join(top.path, 'share', 'applications')).existsSync()
        ? Directory(p.join(top.path, 'share', 'applications'))
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.desktop'))
            .toList()
        : <File>[];
    final appId = desktops.length == 1 ? p.basenameWithoutExtension(desktops.single.path) : '';

    await runner.startDetached('sh', [
      '-c',
      _helper,
      'sh',
      '${currentPid ?? pid}',
      resolved,
      appId,
      update.directory.path,
    ]);
    return InstallOutcome.installerStarted;
  }
}
