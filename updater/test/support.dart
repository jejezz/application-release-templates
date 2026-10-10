import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_updater/app_updater.dart';
import 'package:crypto/crypto.dart';

/// A loopback stand-in for both the release server and GitHub's file hosting.
class FakeServer {
  FakeServer._(this._server);

  final HttpServer _server;

  /// Query parameters of the last `/api/update` request.
  Map<String, String> lastQuery = {};
  int updateCalls = 0;
  int fileCalls = 0;

  /// Answer for `/api/update`; set `status` to change the HTTP code.
  Object? updateBody;
  int updateStatus = 200;
  String? rawUpdateBody;

  /// Bytes served at `/dl/<name>`; null → 404.
  final Map<String, List<int>> files = {};

  /// If set, a file download stalls after sending this many bytes.
  int? stallAfter;
  Completer<void>? stall;

  static Future<FakeServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeServer._(server);
    unawaited(server.forEach(fake._handle));
    return fake;
  }

  String get origin => 'http://127.0.0.1:${_server.port}';
  Uri get serverUri => Uri.parse('$origin/repos');
  List<String> get prefixes => ['$origin/'];

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path;
    if (path == '/repos/api/update') {
      updateCalls++;
      lastQuery = req.uri.queryParameters;
      req.response.statusCode = updateStatus;
      req.response.headers.contentType = ContentType.json;
      req.response.write(rawUpdateBody ?? jsonEncode(updateBody ?? <String, Object?>{}));
    } else if (path.startsWith('/dl/')) {
      fileCalls++;
      final bytes = files[path.substring(4)];
      if (bytes == null) {
        req.response.statusCode = 404;
      } else if (stallAfter != null) {
        req.response.add(bytes.sublist(0, stallAfter));
        await req.response.flush();
        stall = Completer<void>();
        await stall!.future;
      } else {
        req.response.add(bytes);
      }
    } else {
      req.response.statusCode = 404;
    }
    await req.response.close();
  }

  /// A `/api/update` body for "0.2.1 is available" with a real, matching file.
  Map<String, Object?> available({
    String name = 'App-0.2.1-macos-universal.dmg',
    List<int>? bytes,
    String? sha256Hex,
    int? size,
    String? reason,
    String latest = '0.2.1',
    Object? asset,
  }) {
    final data = bytes ?? utf8.encode('pretend dmg contents');
    files[name] = data;
    return {
      'app': 'app-flutter',
      'current': '0.2.0',
      'updateAvailable': true,
      'latest': latest,
      'tag': 'v$latest',
      'publishedAt': '2026-10-07T01:18:45Z',
      'notes': 'notes',
      'releaseUrl': 'https://github.com/jejezz/app-flutter/releases/tag/v$latest',
      'asset': asset ??
          {
            'name': name,
            'url': '$origin/dl/$name',
            'size': size ?? data.length,
            'sha256': sha256Hex ?? sha256.convert(data).toString(),
          },
      if (reason != null) 'reason': reason,
    };
  }
}

const mac = PlatformInfo(os: 'macos', arch: 'arm64');
