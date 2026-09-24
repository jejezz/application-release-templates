---
name: flutter-app-bootstrap
description: Set up a new Flutter app with every shared convention (identity, versioning, release workflows, installers, About dialog, icons, license, l10n, theme, fonts, README, CLAUDE.md) BEFORE any feature code is written — the "앱 구현 전 단계" of jejezz/application-release-templates. Use this whenever the user starts a new Flutter app or project ("새 앱 만들자", "새 프로젝트 시작", "flutter create 해줘", "앱 뼈대/골격 잡아줘", "new desktop app", "start a mobile app called …"), or has a freshly created Flutter project that has no features yet — even if they only mention the app idea and not the conventions.
---

# Flutter app bootstrap (앱 구현 전 단계)

The user builds many Flutter apps in parallel. Everything that isn't the app's
own feature — names and identifiers, versions, release CI, installers, About
dialog, icons, license, languages, themes, fonts, README — follows one set of
conventions so no app rediscovers them. This skill lays all of that down
first, so feature work starts on a finished foundation and the very first tag
already produces a release.

## 0. Find the conventions

This skill lives in the `application-release-templates` repository
(`skills/flutter-app-bootstrap/`). Resolve the repo root from this skill's base
directory and try to update it (it's a clone kept only for these skills):

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only --quiet || echo "could not update $T — using the checked-out version"
git -C "$T" rev-parse --abbrev-ref HEAD      # the branch = the conventions in force
```

The docs in `$T/conventions/` are the authority; this skill is the order of
work. Read the doc a step names before doing it. `$T/common/README.md` lists
exactly which shared files go where.

## 1. Gather what only the user knows

Ask in one go (AskUserQuestion) for whatever the conversation hasn't answered:

- **Display name** in Title Case (e.g. "Dove Zip"). Everything derives from it:
  file name `DoveZip`, package `dove_zip`, repo `dove-zip-flutter`,
  identifier `art.zoomon.dovezip` (`identity.md` §2–3).
- **One-line purpose** — README header and About dialog.
- **Platforms** — desktop (macOS/Windows/Linux), mobile (iOS/Android), or both.
- **Glyph** for the icon — a transparent PNG, usually an Icons8 download.
  Without one, draw a simple temporary glyph with Pillow and list it as a
  remaining item.

Default the location to `~/FlutterProject/<repo>`. Confirm the derived names in
one line before creating anything — identifiers can't change after a release.

## 2. Create the project and fix identity (`identity.md`)

```bash
flutter create --org art.zoomon --project-name <package> --platforms=<list> <repo>
cd <repo> && git init && git remote add origin https://github.com/jejezz/<repo>.git
```

Adding the remote is local only; it lets later tools fill the repository URL.

Flutter derives different identifiers per platform (`art.zoomon.doveZip` on
Apple, `art.zoomon.dove_zip` on Android/Linux). Set all of them to
`art.zoomon.<package without underscores>`:
macOS `AppInfo.xcconfig`; iOS `project.pbxproj` (app and RunnerTests); Android
`applicationId` **and** `namespace` — move `MainActivity.kt` into the matching
package directory and fix its `package` line; Linux `APPLICATION_ID`.

Then the names and copyright (`identity.md` §2, §4):

- `AppInfo.xcconfig`: `PRODUCT_NAME = <Display Name>`,
  `PRODUCT_COPYRIGHT = Copyright © <year> Jongyun Ahn`
- `macos/Runner.xcodeproj/project.pbxproj`: RunnerTests `TEST_HOST` (3 build
  configs) → `<Display Name>.app/…/<Display Name>` — it still points at the
  package name and breaks the Xcode test target otherwise.
- `windows/runner/Runner.rc`: `CompanyName "Jongyun Ahn"`,
  `FileDescription`/`ProductName "<Display Name>"`,
  `LegalCopyright "Copyright (C) <year> Jongyun Ahn"`; the window title in
  `windows/runner/main.cpp` and both titles in `linux/runner/my_application.cc`.
- iOS `CFBundleDisplayName`, Android `android:label`: the display name.
- `pubspec.yaml`: `version: 0.1.0+1` and a real `description`.
- `LICENSE`: MIT, `Copyright (c) <year> Jongyun Ahn` (`licensing.md` §1).

## 3. Shared files and skeleton (`common/README.md`)

Follow `$T/common/README.md` "적용 순서" top to bottom. For a new app copy all
of `common/lib/` **including `main.dart`** — it already wires everything the
conventions ask for: window size (`window_manager`), extra licenses, saved
theme/language (`AppSettings`, keys `theme_mode`/`app_locale`), light/dark
Saturn theme, `localeResolutionCallback`, the macOS app-menu About,
`windowManager.setBrightness`, and the app bar `theme | language | About` over
an empty-state home screen. Don't reinvent any of these; adjust only:

- `lib/app_identity.dart`: display name, repository URL, `firstReleaseYear`.
- ARB: replace the `(앱별)` / `(per app)` values with this app's tagline,
  description and empty-state text, then run `flutter gen-l10n`.
- Window size: 1200×720 for work apps, 960×640 for small utilities
  (`ui-ux.md` §5). Leave the empty-state button disabled until a feature exists.
- `test/*_test.dart`: replace `<package>`.

Assets:
- **Icon**: glyph at `assets/icon/source_glyph.png`, then
  `python3 tool/icon/generate_icons.py`.
- **Fonts**: copy SeoulNamsan 400/700/800 TTFs from another app
  (`~/FlutterProject/*/assets/fonts/seoul_namsan_{regular,bold,extra_bold}.ttf`)
  and declare them as in `fonts.md` §1.
- **Font license**: `assets/licenses/seoul-namsan.txt`. Use the official notice
  from https://www.seoul.go.kr/seoul/font.do if you can fetch it; otherwise
  write a short notice with that URL, mark it "원문 필요", and list it as a
  remaining item. Don't compose license wording yourself (`licensing.md` §3).

## 4. Release pipeline (`workflow.md`, `packaging.md`)

- Desktop: copy `$T/desktop/.github/`, `installer/windows/app.iss`,
  `linux/install.sh`. In `app.iss` set `AppId` to a fresh GUID (`uuidgen`),
  `__REPOSITORY__` in `MyAppURL`, and `MyFirstReleaseYear` if not 2026 (the
  other `__APP_*__` values are local-compile fallbacks CI overrides). In
  `.github/release-notes-header.md` replace `__MIN_MACOS__` with
  `MACOSX_DEPLOYMENT_TARGET` from `macos/Runner.xcodeproj/project.pbxproj`.
- Mobile: copy `$T/mobile/` per its README and replace `__APP_IDENTIFIER__`.
- Tell the user which GitHub secrets the platforms need (tables in the
  desktop/mobile READMEs). Registering them is theirs to do.

## 5. README and CLAUDE.md (`readme-guide.md`)

`python3 tool/readme/init_readme.py` — it replaces flutter create's README,
fills names, repository, platforms and minimum macOS, and writes "coming soon"
placeholder images for the demo GIF and screenshots so the first release
passes the README check (they stay warnings until real captures replace them
with `tool/readme/capture.sh`). Fill every `{{TODO}}` from what the user told
you; keep the screenshot file names (`home.png`, `detail.png`) or rename them
and run `init_readme.py --placeholders`.

Create `CLAUDE.md`: the conventions line from `conventions/README.md` step 10
(`conventions-v1`), the app's purpose, and anything app-specific the user said.

## 6. Verify

```bash
flutter gen-l10n && flutter analyze && flutter test --reporter=failures-only
python3 "$T/tools/audit_app.py" .
```

On macOS also `flutter build macos --debug` once — it catches `TEST_HOST`,
entitlement and plugin problems analyze can't see.

Fix every ❌ the audit reports. Expected leftovers at this stage are only
warnings: placeholder README images, a temporary glyph, the font license
notice. List them.

## 7. Hand-off

Commit on `main` with a Korean Conventional Commit, e.g.
`chore: conventions-v1로 <Display Name> 초기 구성`. Creating the GitHub
repository, pushing, and pushing `v0.1.0` are outward-facing: ask before each.
Recommend the `v0.1.0` tag soon — proving the whole pipeline before feature
work is the point of this stage (`conventions/README.md` step 11).

Finish with a short Korean summary: what was created, the audit result,
secrets to register, remaining items (glyph, screenshots, font license, tag).
