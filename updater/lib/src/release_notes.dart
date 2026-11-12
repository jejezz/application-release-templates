/// The user-facing changes in a release, short enough for an update dialog.
///
/// GitHub release notes are Markdown written for people downloading by hand:
/// the generated "What's Changed" list (with `by @someone in <PR url>`), a
/// Full Changelog link and, in these apps, an install guide header
/// (`desktop/.github/release-notes-header.md`). Showing that raw in a dialog
/// is long and unreadable, so the dialog shows [items] and links to the
/// release page for the rest.
final class ReleaseNotesSummary {
  const ReleaseNotesSummary(this.items, this.more);

  static const empty = ReleaseNotesSummary([], 0);

  final List<String> items;

  /// How many items were left out because of the limit.
  final int more;

  bool get isEmpty => items.isEmpty;

  /// Rules (the Avalonia app's `ReleaseNotesSummary.From` follows the same):
  /// - stop at the first horizontal rule (`---`) or `**Full Changelog**`, and
  ///   skip the "New Contributors" section;
  /// - take list items (`* `, `- `); if there are none, take paragraph lines
  ///   that are not headings, tables or quotes;
  /// - drop the trailing `by @user in https://…`;
  /// - strip Conventional Commits prefixes and leave out kinds people don't
  ///   see (chore, ci, build, docs, test, style, refactor);
  /// - remove inline Markdown (links, bold, code).
  static ReleaseNotesSummary from(String? markdown, {int max = 6}) {
    if (markdown == null || markdown.trim().isEmpty) return empty;
    final bullets = <String>[];
    final paragraphs = <String>[];
    var skipSection = false;
    for (final raw in markdown.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      if (_rule.hasMatch(line) || line.trimLeft().toLowerCase().startsWith('**full changelog**')) break;
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        skipSection = heading.group(1)!.trim().toLowerCase() == 'new contributors';
        continue;
      }
      if (skipSection || line.trim().isEmpty) continue;

      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        final item = _clean(bullet.group(1)!);
        if (item != null) bullets.add(item);
      } else if (!line.trimLeft().startsWith('|') && !line.trimLeft().startsWith('>')) {
        final text = _clean(line);
        if (text != null) paragraphs.add(text);
      }
    }

    final items = (bullets.isNotEmpty ? bullets : paragraphs).toSet().toList();
    return items.length <= max
        ? ReleaseNotesSummary(items, 0)
        : ReleaseNotesSummary(items.sublist(0, max), items.length - max);
  }

  static const _hidden = {'chore', 'ci', 'build', 'docs', 'doc', 'test', 'tests', 'style', 'refactor'};

  static final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
  static final _bullet = RegExp(r'^\s{0,3}[-*+]\s+(.+)$');
  static final _attribution = RegExp(r'\s+by\s+@[\w.\-\[\]]+\s+in\s+\S+\s*$');
  static final _firstContribution = RegExp(r'^@\S+\s+made their first contribution', caseSensitive: false);
  static final _prefix = RegExp(r'^([A-Za-z]+)(\([^)]*\))?!?:\s*');
  static final _link = RegExp(r'\[([^\]]+)\]\([^)]*\)');
  static final _space = RegExp(r'\s+');

  /// One item, tidied; null when people should not see it.
  static String? _clean(String text) {
    var s = text.trim().replaceFirst(_attribution, '');
    if (_firstContribution.hasMatch(s)) return null;
    final prefix = _prefix.firstMatch(s);
    if (prefix != null) {
      if (_hidden.contains(prefix.group(1)!.toLowerCase())) return null;
      s = s.substring(prefix.end);
    }
    s = s
        .replaceAllMapped(_link, (m) => m.group(1)!)
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .replaceAll(_space, ' ')
        .trim();
    return s.isEmpty ? null : s;
  }
}
