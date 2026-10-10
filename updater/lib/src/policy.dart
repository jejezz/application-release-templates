/// Where the app keeps two small values. The UI template backs this with
/// `shared_preferences`; the package itself stays free of Flutter.
abstract interface class UpdateStateStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Memory-only store (tests, or apps that do not want persistence).
final class MemoryUpdateStateStore implements UpdateStateStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

/// When to check on its own, and which version the person said no to.
final class UpdatePolicy {
  UpdatePolicy(
    this._store, {
    this.interval = const Duration(hours: 24),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const lastCheckKey = 'update.lastCheckMs';
  static const skippedVersionKey = 'update.skippedVersion';

  final UpdateStateStore _store;
  final Duration interval;
  final DateTime Function() _now;

  /// True when no automatic check has succeeded within [interval].
  Future<bool> isDue() async {
    final last = int.tryParse(await _store.read(lastCheckKey) ?? '');
    if (last == null) return true;
    final elapsed = _now().millisecondsSinceEpoch - last;
    // A clock set back counts as due rather than "never check again".
    return elapsed < 0 || elapsed >= interval.inMilliseconds;
  }

  Future<void> markChecked() =>
      _store.write(lastCheckKey, '${_now().millisecondsSinceEpoch}');

  Future<bool> isSkipped(String version) async =>
      await _store.read(skippedVersionKey) == version;

  /// "Skip this version" — a still-newer version is announced again.
  Future<void> skip(String version) => _store.write(skippedVersionKey, version);
}
