import 'package:app_updater/app_updater.dart';
import 'package:test/test.dart';

// A real release (generate-notes + the install guide header).
const _gitHubNotes = '''
## What's Changed
* feat: 대화상자를 타이틀바 없는 모달로, 보조 단추를 글자 단추로 (창 크롬 정책) by @jejezz in https://github.com/jejezz/daylight-commander-avalonia/pull/28
* chore(release): v1.4.3 by @jejezz in https://github.com/jejezz/daylight-commander-avalonia/pull/29


**Full Changelog**: https://github.com/jejezz/daylight-commander-avalonia/compare/v1.4.2...v1.4.3


---

## 설치 / Install

| OS | 받을 파일 / File |
|---|---|
| Windows 10/11 (x64) | `*-windows-x64-setup.exe` (설치 프로그램) |

**Windows**: 설치 프로그램에 아직 코드 서명이 없어서 SmartScreen이 창을 띄웁니다.
- 목록처럼 보이는 설치 안내
''';

void main() {
  group('ReleaseNotesSummary', () {
    test('GitHub notes keep only user-facing changes', () {
      final s = ReleaseNotesSummary.from(_gitHubNotes);
      expect(s.items, ['대화상자를 타이틀바 없는 모달로, 보조 단추를 글자 단추로 (창 크롬 정책)']);
      expect(s.more, 0);
    });

    test('Conventional prefixes are stripped and internal kinds hidden', () {
      final s = ReleaseNotesSummary.from('''
* fix(windows): 경로 오류 고침 by @a in https://x/pull/1
- feat!: 큰 변경 by @dependabot[bot] in https://x/pull/2
* ci: 워크플로 by @a in https://x/pull/3
* docs: README by @a in https://x/pull/4
* refactor(core): 정리
* perf: 목록이 빨라짐
* 접두어 없는 항목
''');
      expect(s.items, ['경로 오류 고침', '큰 변경', '목록이 빨라짐', '접두어 없는 항목']);
    });

    test('New Contributors section is dropped', () {
      final s = ReleaseNotesSummary.from('''
## What's Changed
* feat: 새 기능 by @b in https://x/pull/5

## New Contributors
* @b made their first contribution in https://x/pull/5
''');
      expect(s.items, ['새 기능']);
    });

    test('inline Markdown is removed', () {
      final s = ReleaseNotesSummary.from('* feat: **굵게**, `코드`, [링크](https://x) 지원');
      expect(s.items, ['굵게, 코드, 링크 지원']);
    });

    test('long lists are capped with a count', () {
      final notes = [for (var i = 1; i <= 9; i++) '* feat: 항목 $i'].join('\n');
      final s = ReleaseNotesSummary.from(notes, max: 6);
      expect(s.items, hasLength(6));
      expect(s.items.last, '항목 6');
      expect(s.more, 3);
    });

    test('hand-written paragraphs are used when there is no list', () {
      final s = ReleaseNotesSummary.from('''
# 1.5.0
탭을 **끌어서** 옮길 수 있습니다.

| 표 | 는 |
---
설치 안내
''');
      expect(s.items, ['탭을 끌어서 옮길 수 있습니다.']);
    });

    for (final notes in [null, '', '  \n ', '* chore(release): v1.4.3 by @jejezz in https://x/pull/29']) {
      test('nothing to show: ${notes == null ? 'null' : '"${notes.trim()}"'}', () {
        final s = ReleaseNotesSummary.from(notes);
        expect(s.isEmpty, isTrue);
        expect(s.more, 0);
      });
    }
  });
}
