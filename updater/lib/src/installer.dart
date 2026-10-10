import 'dart:io';

import 'models.dart';

/// A verified installer file waiting in a temp directory.
final class DownloadedUpdate {
  const DownloadedUpdate({required this.info, required this.file});

  final UpdateInfo info;
  final File file;

  /// App-private temp directory that holds [file]; safe to delete wholesale.
  Directory get directory => file.parent;
}

enum InstallOutcome {
  /// An installer process was started. The app should quit now so it can
  /// replace the running files.
  installerStarted,

  /// The file was opened for the person to finish (macOS: the DMG window).
  /// The app keeps running.
  openedForUser,
}

/// Starts the OS-specific installation. Implementations live per OS so the
/// process runner can be faked in tests.
abstract interface class UpdateInstaller {
  Future<InstallOutcome> install(DownloadedUpdate update);
}
