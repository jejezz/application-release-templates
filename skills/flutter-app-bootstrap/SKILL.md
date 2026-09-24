---
name: flutter-app-bootstrap
description: Set up a new Flutter app with every shared convention (identity, versioning, release workflows, installers, About dialog, icons, license, l10n, theme, fonts, README, CLAUDE.md) BEFORE any feature code is written — the "앱 구현 전 단계" of jejezz/application-release-templates. Use this whenever the user starts a new Flutter app or project ("새 앱 만들자", "새 프로젝트 시작", "flutter create 해줘", "앱 뼈대/골격 잡아줘", "new desktop app", "start a mobile app called …"), or has a freshly created Flutter project that has no features yet — even if they only mention the app idea and not the conventions.
---

# Flutter app bootstrap (앱 구현 전 단계)

The user builds many Flutter apps in parallel. Everything that isn't the app's
own feature — names and identifiers, versions, release CI, installers, About
dialog, icons, license, languages, themes, fonts, README — follows one set of
conventions so no app has to rediscover them. This skill lays all of that down
first, so feature work starts on a finished foundation and the first release
tag already works.

## 0. Find the conventions

This skill lives in the `application-release-templates` repository
(`skills/flutter-app-bootstrap/`). Resolve the repo root from this skill's base
directory and update it:

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only || echo "templates repo has local changes — using as is"
```

`$T/conventions/README.md` has the checklist this skill follows; each step
below names the convention doc that defines it. Read the relevant doc before
doing a step — the docs are the authority, this skill is the order of work.
`$T/common/README.md`, `$T/desktop/README.md` and `$T/mobile/README.md` say
exactly which files to copy where.

## 1. Gather what only the user knows

Ask in one go (AskUserQuestion) for whatever the conversation hasn't answered:

- **Display name** in Title Case (e.g. "Dove Zip"). Everything else derives
  from it: file name `DoveZip`, package `dove_zip`, repo `dove-zip-flutter`,
  identifier `art.zoomon.dovezip` (`conventions/identity.md` §2–3).
- **One-line purpose** — goes into the README header and About dialog.
- **Platforms** — desktop (macOS/Windows/Linux), mobile (iOS/Android), or both.
- **Glyph** for the icon — a transparent PNG (usually an Icons8 download).
  If there isn't one yet, continue with a temporary glyph and list it as a
  remaining item.

Default the location to `~/FlutterProject/<repo>` unless the user is already in
an empty project folder. Confirm the derived names in one line before creating
anything — renaming identifiers after a release is not possible.

## 2. Create the project and fix identity (`identity.md`)

```bash
flutter create --org art.zoomon --project-name <package> --platforms=<list> <repo>
```

Flutter derives different identifiers per platform (`art.zoomon.doveZip` on
Apple, `art.zoomon.dove_zip` on Android/Linux). Set them all to
`art.zoomon.<package without underscores>`: macOS `AppInfo.xcconfig`, iOS
`project.pbxproj`, Android `applicationId` **and** `namespace` (move
`MainActivity.kt` to the matching package directory and update its
`package` line), Linux `APPLICATION_ID`. Then:

- `AppInfo.xcconfig`: `PRODUCT_NAME = <Display Name>`,
  `PRODUCT_COPYRIGHT = Copyright © <year> Jongyun Ahn`
- `windows/runner/Runner.rc`: `CompanyName "Jongyun Ahn"`,
  `ProductName "<Display Name>"`, `LegalCopyright "Copyright (C) <year> Jongyun Ahn"`
- iOS `CFBundleDisplayName`, Android `android:label`: the display name
- `pubspec.yaml`: `version: 0.1.0+1`, a real `description`

`git init`, then add `LICENSE` (MIT, `Copyright (c) <year> Jongyun Ahn`,
`licensing.md` §1).

## 3. Copy the shared files (`common/README.md`)

Follow `$T/common/README.md` "적용 순서" top to bottom: `lib/app_identity.dart`
(fill it), About dialog, `extra_licenses.dart`, `l10n.yaml` + ARB keys, pubspec
dependencies and assets, `tool/icon/`, `scripts/bump-version.sh`,
`tool/readme/`. Put the glyph at `assets/icon/source_glyph.png` and run
`python3 tool/icon/generate_icons.py`.

## 4. App skeleton (`ui-ux.md`, `theming.md`, `localization.md`, `fonts.md`)

There is no shared UI package yet (`ui-ux.md` §2), so the reference
implementation is dove-zip's `lib/presentation/theme/`. Read it from the local
clone without touching that repo:
`git -C ~/FlutterProject/dove-zip-flutter show origin/main:lib/presentation/theme/app_theme.dart`
(fall back to `gh api repos/jejezz/dove-zip-flutter/contents/...`). Copy it
with a first-line comment naming the source, then bring it in line with the
docs where dove-zip differs:

- **Theme**: system / light / dark, persisted as `theme_mode`
  (`ThemeMode.name`); Saturn palette from `theming.md` §2, no `fromSeed`.
- **Language**: ko template + en, `app_locale` key,
  `localeResolutionCallback` (ko → ko, everything else → en).
- **Switchers**: app-bar icon buttons that open a checked popup menu
  (desktop) or a `SegmentedButton` in settings (mobile) — not cycle buttons.
  App-bar order at the right edge: theme | language | About.
- **Fonts**: SeoulNamsan 400/700/800 (copy the TTFs from another app's
  `assets/fonts/`), `fontFamilyFallback`, mono family list; license text in
  `assets/licenses/seoul-namsan.txt` + `registerExtraLicenses()` in `main()`.
- **Desktop window**: `window_manager` `WindowOptions(size, minimumSize ≤ 960×600, title)`;
  call `windowManager.setBrightness` when the theme changes.
- A placeholder home screen with the empty-state pattern (`ui-ux.md` §6) so
  the app runs and screenshots have something to show.

## 5. Release pipeline (`workflow.md`, `packaging.md`)

- Desktop: copy `$T/desktop/.github/`, `installer/windows/app.iss`,
  `linux/install.sh`. In `app.iss` set `AppId` to a fresh GUID
  (`uuidgen`) and `MyAppURL`; in `release-notes-header.md` set the minimum
  macOS version.
- Mobile: copy `$T/mobile/` per its README and replace `__APP_IDENTIFIER__`.
- Tell the user which GitHub secrets the platforms need (tables in the
  desktop/mobile READMEs); registering them is theirs to do.

## 6. README and CLAUDE.md (`readme-guide.md`)

`python3 tool/readme/init_readme.py`, then fill every `{{TODO}}` you can from
what the user told you. Screenshots and the demo GIF need the running app and
the Screen Recording permission — leave those for later and say so.

Create `CLAUDE.md` with the conventions line from `conventions/README.md` step
10 (including `conventions-v1`), plus the app's purpose and anything
app-specific the user mentioned.

## 7. Verify

```bash
flutter analyze && flutter test
python3 "$T/tools/audit_app.py" .
```

Add a widget test that opens the About dialog and finds the version text
(`about-dialog.md` §4). Fix every ❌ the audit reports. The only acceptable
leftovers at this stage are README screenshot/GIF placeholders and a missing
real glyph — list them explicitly.

## 8. Hand-off

Commit on `main` (`chore: bootstrap <Display Name> with conventions-v1`).
Creating the GitHub repository, pushing, and pushing the first `v0.1.0` tag
are outward-facing: ask before each. Recommend tagging `v0.1.0` early —
the conventions want the whole pipeline proven before feature work
(`conventions/README.md` step 11).

Finish with a short summary: what was created, the audit result, secrets to
register, and remaining items (glyph, screenshots, first tag).
