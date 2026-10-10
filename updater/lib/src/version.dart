/// SemVer subset used by the release server (`introduce-public-repos`'s
/// `src/update.js`): `1.2.3`, `v1.2.3`, `1.2.3-rc.1`, `1.2.3+4`.
///
/// Build metadata (`+4`, Flutter's build number) is ignored when comparing,
/// the same way the server does it. test/vectors/version.json is shared with
/// the server's tests so the two implementations cannot drift apart.
final class AppVersion implements Comparable<AppVersion> {
  AppVersion._(this.major, this.minor, this.patch, this.preRelease);

  final int major;
  final int minor;
  final int patch;

  /// Pre-release identifiers: each is an `int` or a `String`.
  final List<Object> preRelease;

  static final _pattern = RegExp(
    r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
  );

  /// Returns null when [text] is not a version.
  static AppVersion? tryParse(String text) {
    final m = _pattern.firstMatch(text.trim());
    if (m == null) return null;
    final pre = m.group(4);
    return AppVersion._(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      pre == null
          ? const []
          : [for (final id in pre.split('.')) int.tryParse(id) ?? id],
    );
  }

  /// Throws [FormatException] when [text] is not a version.
  factory AppVersion.parse(String text) =>
      tryParse(text) ?? (throw FormatException('Not a version', text));

  bool get isPreRelease => preRelease.isNotEmpty;

  @override
  int compareTo(AppVersion other) {
    final nums = [major.compareTo(other.major), minor.compareTo(other.minor), patch.compareTo(other.patch)];
    for (final c in nums) {
      if (c != 0) return c;
    }
    // A release is newer than any pre-release of the same numbers.
    if (preRelease.isEmpty || other.preRelease.isEmpty) {
      if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
      return preRelease.isEmpty ? 1 : -1;
    }
    final n = preRelease.length > other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < n; i++) {
      if (i >= preRelease.length) return -1;
      if (i >= other.preRelease.length) return 1;
      final a = preRelease[i];
      final b = other.preRelease[i];
      if (a == b) continue;
      if (a is int && b is int) return a.compareTo(b);
      if (a is int) return -1; // numeric identifiers sort before text
      if (b is int) return 1;
      return (a as String).compareTo(b as String);
    }
    return 0;
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch, Object.hashAll(preRelease));

  /// Canonical text without build metadata: `1.2.3` or `1.2.3-rc.1`.
  @override
  String toString() =>
      '$major.$minor.$patch${preRelease.isEmpty ? '' : '-${preRelease.join('.')}'}';
}
