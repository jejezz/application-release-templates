import 'dart:convert';
import 'dart:io';

import 'package:app_updater/app_updater.dart';
import 'package:test/test.dart';

void main() {
  final vectors =
      jsonDecode(File('test/vectors/version.json').readAsStringSync()) as Map<String, Object?>;

  test('rejects what the server rejects', () {
    for (final text in (vectors['invalid']! as List<Object?>).cast<String>()) {
      expect(AppVersion.tryParse(text), isNull, reason: '"$text"');
    }
  });

  test('accepts what the server accepts', () {
    for (final text in (vectors['valid']! as List<Object?>).cast<String>()) {
      expect(AppVersion.tryParse(text), isNotNull, reason: '"$text"');
    }
  });

  test('compares like the server (shared vectors)', () {
    for (final row in (vectors['compare']! as List<Object?>).cast<List<Object?>>()) {
      final a = AppVersion.parse(row[0]! as String);
      final b = AppVersion.parse(row[1]! as String);
      final want = row[2]! as int;
      expect(a.compareTo(b).sign, want, reason: '${row[0]} vs ${row[1]}');
      expect(b.compareTo(a).sign, -want, reason: '${row[1]} vs ${row[0]}');
    }
  });

  test('toString drops build metadata and v', () {
    expect(AppVersion.parse('v1.2.3+4').toString(), '1.2.3');
    expect(AppVersion.parse('1.2.3-rc.1+9').toString(), '1.2.3-rc.1');
  });
}
