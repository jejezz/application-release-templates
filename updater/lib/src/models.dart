import 'errors.dart';

/// The installer file the server picked for this OS and architecture.
final class UpdateAsset {
  const UpdateAsset({
    required this.name,
    required this.url,
    required this.size,
    required this.sha256,
  });

  final String name;
  final Uri url;
  final int size;

  /// Lower-case hex, 64 characters.
  final String sha256;
}

/// A newer version that can be downloaded and verified automatically.
final class UpdateInfo {
  const UpdateInfo({
    required this.appId,
    required this.currentVersion,
    required this.latestVersion,
    required this.tag,
    required this.notes,
    required this.asset,
    this.releaseUrl,
    this.publishedAt,
  });

  final String appId;
  final String currentVersion;

  /// Normalized (`1.2.3`, `1.2.3-rc.1`) — what to show and what to remember
  /// when the user skips this version.
  final String latestVersion;
  final String tag;

  /// Release notes, truncated by the server. Send people to [releaseUrl] for more.
  final String notes;
  final Uri? releaseUrl;
  final DateTime? publishedAt;
  final UpdateAsset asset;
}

enum UnavailableReason {
  /// The release has a file for this platform but no usable SHA-256, so it
  /// must not be installed automatically.
  noChecksum,

  /// The release has no file for this OS/architecture.
  noAssetForPlatform,
}

sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

/// Nothing newer (also: the app is newer than the server's latest release).
final class UpToDate extends UpdateCheckResult {
  const UpToDate({this.latestVersion});
  final String? latestVersion;
}

final class UpdateAvailable extends UpdateCheckResult {
  const UpdateAvailable(this.info);
  final UpdateInfo info;
}

/// A newer version exists but cannot be installed by the app. Show
/// [releaseUrl] so the person can get it by hand.
final class UpdateUnavailable extends UpdateCheckResult {
  const UpdateUnavailable({
    required this.reason,
    required this.latestVersion,
    this.releaseUrl,
  });

  final UnavailableReason reason;
  final String latestVersion;
  final Uri? releaseUrl;
}

final class UpdateCheckFailed extends UpdateCheckResult {
  const UpdateCheckFailed(this.error);
  final UpdateException error;
}
