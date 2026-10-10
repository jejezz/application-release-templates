import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'cancel.dart';
import 'errors.dart';
import 'installer.dart';
import 'models.dart';
import 'platform.dart';
import 'policy.dart';
import 'version.dart';

typedef ProgressCallback = void Function(int received, int total);

/// Asks the release server whether a newer version exists, downloads it, and
/// verifies it. See docs/APP_UPDATER_DESIGN.md (introduce-public-repos).
///
/// Safety rules enforced here, not left to callers:
///  * the server must be `https` (plain http only for loopback, for tests);
///  * a download URL must start with one of [downloadUrlPrefixes]
///    (`https://github.com/` by default);
///  * a file is only returned when both the announced size and SHA-256 match;
///  * nothing is installed without a SHA-256 from the server.
class AppUpdater {
  AppUpdater({
    required Uri server,
    required this.appId,
    required String currentVersion,
    PlatformInfo? platform,
    http.Client? httpClient,
    this.installer,
    this.downloadUrlPrefixes = const ['https://github.com/'],
    this.requestTimeout = const Duration(seconds: 10),
    Directory? tempRoot,
  })  : _server = _checkServer(server),
        _current = AppVersion.tryParse(currentVersion) ??
            (throw ArgumentError.value(
                currentVersion, 'currentVersion', 'not a version')),
        _platform = platform ?? PlatformInfo.current(),
        _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null,
        _tempRoot = tempRoot {
    if (!_appIdPattern.hasMatch(appId)) {
      throw ArgumentError.value(appId, 'appId', 'not a repository name');
    }
  }

  static final _appIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,100}$');
  static final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  /// The repository name the server knows this app by
  /// (`AppIdentity.repositoryUrl`'s last path segment).
  final String appId;
  final UpdateInstaller? installer;
  final List<String> downloadUrlPrefixes;
  final Duration requestTimeout;

  final Uri _server;
  final AppVersion _current;
  final PlatformInfo _platform;
  final http.Client _http;
  final bool _ownsClient;
  final Directory? _tempRoot;

  static Uri _checkServer(Uri server) {
    if (server.scheme == 'https' || _isLoopbackHttp(server)) {
      return server;
    }
    throw UpdateException(UpdateErrorKind.insecureUrl,
        'The update server must be https (got ${server.scheme}://${server.host})');
  }

  Uri get _checkUri {
    final base = _server.path.replaceFirst(RegExp(r'/+$'), '');
    return _server.replace(
      path: '$base/api/update',
      queryParameters: {
        'app': appId,
        'version': _current.toString(),
        'os': _platform.os,
        'arch': _platform.arch,
      },
    );
  }

  /// Never throws for expected trouble: the result says what happened.
  Future<UpdateCheckResult> check() async {
    try {
      final json = await _getJson(_checkUri);
      return _interpret(json);
    } on UpdateException catch (e) {
      return UpdateCheckFailed(e);
    }
  }

  /// For the automatic check at app start. Returns null — meaning "say nothing"
  /// — when a check is not due yet, the check failed, or the person already
  /// skipped that version. A manual "check for updates" button should call
  /// [check] instead, which ignores all of that.
  Future<UpdateCheckResult?> checkAutomatically(UpdatePolicy policy) async {
    if (!await policy.isDue()) return null;
    final result = await check();
    if (result is UpdateCheckFailed) return null; // try again next start
    await policy.markChecked();
    final newer = switch (result) {
      UpdateAvailable(:final info) => info.latestVersion,
      UpdateUnavailable(:final latestVersion) => latestVersion,
      _ => null,
    };
    if (newer != null && await policy.isSkipped(newer)) return null;
    return result;
  }

  Future<Map<String, Object?>> _getJson(Uri uri) async {
    final http.Response res;
    try {
      res = await _http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'app_updater/0.1 ($appId)',
      }).timeout(requestTimeout);
    } catch (e) {
      throw UpdateException(UpdateErrorKind.network, 'Could not reach the update server: $e', cause: e);
    }
    if (res.statusCode == 404) {
      throw UpdateException(UpdateErrorKind.unknownApp, 'The server does not know "$appId"');
    }
    if (res.statusCode != 200) {
      throw UpdateException(UpdateErrorKind.server, 'Update server answered HTTP ${res.statusCode}');
    }
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException catch (e) {
      throw UpdateException(UpdateErrorKind.badResponse, 'Update server sent invalid JSON', cause: e);
    }
    throw UpdateException(UpdateErrorKind.badResponse, 'Update server sent an unexpected JSON shape');
  }

  UpdateCheckResult _interpret(Map<String, Object?> json) {
    UpdateException bad(String what) =>
        UpdateException(UpdateErrorKind.badResponse, 'Update response: $what');

    final available = json['updateAvailable'];
    if (available is! bool) throw bad('updateAvailable is missing');
    final latestText = json['latest'];
    if (!available) {
      return UpToDate(latestVersion: latestText is String ? latestText : null);
    }
    if (latestText is! String) throw bad('latest is missing');
    final latest = AppVersion.tryParse(latestText);
    if (latest == null) throw bad('latest is not a version ($latestText)');
    // Never move backwards, whatever the server says.
    if (_current.compareTo(latest) >= 0) return UpToDate(latestVersion: latestText);

    final releaseUrl = _httpsUri(json['releaseUrl']);
    final assetJson = json['asset'];
    final reason = json['reason'];

    if (assetJson == null || reason == 'no-asset-for-platform') {
      return UpdateUnavailable(
        reason: UnavailableReason.noAssetForPlatform,
        latestVersion: latest.toString(),
        releaseUrl: releaseUrl,
      );
    }
    if (assetJson is! Map<String, Object?>) throw bad('asset is malformed');

    final name = assetJson['name'];
    final url = _httpsUri(assetJson['url']);
    final size = assetJson['size'];
    final sha = assetJson['sha256'];
    if (name is! String || url == null || size is! int || size <= 0) {
      throw bad('asset is incomplete');
    }
    // No checksum (or one we cannot read) means we cannot vouch for the file.
    if (sha is! String || !_sha256Pattern.hasMatch(sha.toLowerCase()) || reason == 'no-checksum') {
      return UpdateUnavailable(
        reason: UnavailableReason.noChecksum,
        latestVersion: latest.toString(),
        releaseUrl: releaseUrl,
      );
    }
    return UpdateAvailable(UpdateInfo(
      appId: appId,
      currentVersion: _current.toString(),
      latestVersion: latest.toString(),
      tag: json['tag'] is String ? json['tag']! as String : latestText,
      notes: json['notes'] is String ? json['notes']! as String : '',
      releaseUrl: releaseUrl,
      publishedAt: json['publishedAt'] is String
          ? DateTime.tryParse(json['publishedAt']! as String)
          : null,
      asset: UpdateAsset(
        name: name,
        url: url,
        size: size,
        sha256: sha.toLowerCase(),
      ),
    ));
  }

  /// https only — plain http just for loopback, the same exception as the server URL.
  Uri? _httpsUri(Object? value) {
    if (value is! String) return null;
    final u = Uri.tryParse(value);
    if (u == null || u.host.isEmpty) return null;
    return u.scheme == 'https' || _isLoopbackHttp(u) ? u : null;
  }

  bool _urlAllowed(Uri url) {
    final text = url.toString();
    return downloadUrlPrefixes.any(text.startsWith) &&
        (url.scheme == 'https' || _isLoopbackHttp(url));
  }

  static const _loopbackHosts = {'localhost', '127.0.0.1', '::1', '[::1]'};

  static bool _isLoopbackHttp(Uri url) => url.scheme == 'http' && _loopbackHosts.contains(url.host);

  /// Downloads [info]'s installer into an app-private temp directory and
  /// verifies size and SHA-256. On any failure the temp directory is removed
  /// and an [UpdateException] is thrown. Call only after the person agreed.
  Future<DownloadedUpdate> download(
    UpdateInfo info, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    final asset = info.asset;
    if (!_urlAllowed(asset.url)) {
      throw UpdateException(UpdateErrorKind.insecureUrl,
          'Refusing to download from ${asset.url.host} — not an allowed location');
    }
    final fileName = p.basename(asset.name);
    if (fileName != asset.name ||
        fileName.isEmpty ||
        fileName.startsWith('.') ||
        fileName.length > 200 ||
        fileName.codeUnits.any((c) => c < 0x20)) {
      throw UpdateException(UpdateErrorKind.badResponse, 'Unsafe file name: ${asset.name}');
    }

    final dir = await (_tempRoot ?? Directory.systemTemp).createTemp('app_updater_');
    try {
      final part = File(p.join(dir.path, '$fileName.part'));
      await _fetchVerified(asset, part, onProgress, cancel);
      final file = await part.rename(p.join(dir.path, fileName));
      return DownloadedUpdate(info: info, file: file);
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  Future<void> _fetchVerified(
    UpdateAsset asset,
    File target,
    ProgressCallback? onProgress,
    CancelToken? cancel,
  ) async {
    final http.StreamedResponse res;
    try {
      res = await _http.send(http.Request('GET', asset.url)
        ..headers['User-Agent'] = 'app_updater/0.1 ($appId)').timeout(requestTimeout);
    } catch (e) {
      throw UpdateException(UpdateErrorKind.network, 'Could not start the download: $e', cause: e);
    }
    if (res.statusCode != 200) {
      throw UpdateException(UpdateErrorKind.server, 'Download answered HTTP ${res.statusCode}');
    }

    final digest = _DigestCapture();
    final hasher = sha256.startChunkedConversion(digest);
    final out = target.openWrite();
    var received = 0;
    try {
      // The timeout is per chunk: a stalled connection fails, a slow one does not.
      await for (final chunk in res.stream.timeout(requestTimeout)) {
        if (cancel?.isCancelled ?? false) {
          throw UpdateException(UpdateErrorKind.cancelled, 'Download cancelled');
        }
        received += chunk.length;
        if (received > asset.size) {
          throw UpdateException(UpdateErrorKind.sizeMismatch,
              'The download is larger than the announced ${asset.size} bytes');
        }
        hasher.add(chunk);
        out.add(chunk);
        onProgress?.call(received, asset.size);
      }
    } on UpdateException {
      rethrow;
    } catch (e) {
      throw UpdateException(UpdateErrorKind.network, 'The download was interrupted: $e', cause: e);
    } finally {
      hasher.close();
      await out.close();
    }

    if (received != asset.size) {
      throw UpdateException(UpdateErrorKind.sizeMismatch,
          'Expected ${asset.size} bytes, got $received');
    }
    if (digest.value.toString() != asset.sha256) {
      throw UpdateException(UpdateErrorKind.checksumMismatch,
          'SHA-256 of ${asset.name} does not match the release');
    }
  }

  /// Starts the OS installer. Only call with a [DownloadedUpdate] from [download].
  Future<InstallOutcome> install(DownloadedUpdate update) async {
    final i = installer;
    if (i == null) {
      throw UpdateException(UpdateErrorKind.unsupportedPlatform,
          'No installer is configured for ${_platform.os}');
    }
    return await i.install(update);
  }

  /// Removes a downloaded file (for example when the person cancels at the end).
  Future<void> discard(DownloadedUpdate update) => _deleteQuietly(update.directory);

  Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      // Temp files are cleaned by the OS eventually.
    }
  }

  void close() {
    if (_ownsClient) _http.close();
  }
}

class _DigestCapture implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}
