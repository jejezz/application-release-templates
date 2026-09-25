---
name: flutter-app-convention-audit
description: Audit an existing (older) Flutter app against the shared conventions in jejezz/application-release-templates and bring it up to date — the "구형 앱 확인 및 수정". Reports every gap (identity, versioning, release workflow, installers, About dialog, icons, license, l10n, theme, fonts, README, CLAUDE.md), plans the fixes by risk and dependency, and applies them area by area on a branch without breaking released identifiers or user settings. Use this whenever the user wants to check or modernize an app that predates the conventions ("이 앱 규약에 맞는지 봐줘", "옛날 앱 정리", "템플릿 최신으로 맞춰줘", "conventions 적용", "portside 업데이트", "audit this app") — or mentions that an app is out of date with the others.
---

# Convention audit & fix (구형 앱 확인 및 수정)

Apps written before the conventions each solved release, About, icons, l10n
and so on their own way. This skill measures the gap, fixes it in a safe order
and leaves the app indistinguishable from a freshly bootstrapped one — without
breaking what existing users have: installed apps must keep upgrading, and
saved settings must survive.

## 0. Find the conventions and sync the app

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only --quiet || echo "could not update $T — using the checked-out version"
```

Local checkouts of these apps are often far behind `origin`. Audit what's
really there:

```bash
git fetch --tags origin
git status -sb                 # behind? local changes? unpushed commits?
```

If the branch is only behind, `git pull --ff-only`. If there are local changes
or unpushed commits, stop and show them — they're the user's work in progress.
Note any tag not on `main` (`git branch -a --contains <tag>`): a release built
from an unmerged branch means `main` is behind what users run.

## 1. Audit

```bash
python3 "$T/tools/audit_app.py" <app> --stage maintain
```

`maintain` lists every gap (the full debt list) without release readiness —
that's the release-check skill's job.

`<app>` is the folder with `pubspec.yaml` — a subfolder such as `gui/` when the
Flutter app sits beside other code (a Rust crate). Repository-level files
(`.github/`, `LICENSE`, `CLAUDE.md`, `README*.md`, `scripts/`, `installer/`,
`tool/readme/`) are then checked at the git root.

Then read the app's row in `$T/conventions/survey-2026-09.md` ("규약 적용 시
앱별 할 일") for things the script can't see — but it's a snapshot from
2026-09-24: confirm each item in the code before planning it; drop the ones
already fixed.

## 2. Plan by risk and dependency, then ask

Show a plan table (area · what changes · risk · effort) and ask which areas to
do now (AskUserQuestion, multi-select; default: all). Don't edit before the
answer. Some areas depend on others — plan them together or use the stopgap:

| # | Area | Convention | Watch out for |
|---|---|---|---|
| 1 | Identity strings, LICENSE | `identity.md`, `licensing.md` | **Never change a released bundle id / applicationId / Windows `AppId`** — installed copies stop upgrading. Change only display strings (copyright, publisher, `CompanyName`, `FileDescription`). If `PRODUCT_NAME` changes, fix the macOS RunnerTests `TEST_HOST`. |
| 2 | Version sync | `versioning.md`, `tagging.md` | Bring `main` up to the latest tag by merging, never by moving/deleting tags. Hardcoded versions → `package_info_plus`. Add `scripts/bump-version.sh` (build number becomes +1 from here on). |
| 3 | Release workflow, installers | `workflow.md`, `packaging.md` | Keep the app's own build steps (brew/apt packages, Rust, wrapper scripts). Keep the existing `AppId` GUID. Users will see: new artifact names, `SHA256SUMS.txt`, pinned macOS runner, unchecked desktop-icon default; add `[InstallDelete]` for shortcuts the old installer put elsewhere. **Needs** `linux/runner/resources/app_icon.png` (area 5) — without the glyph, stopgap: `sips -z 512 512 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png --out linux/runner/resources/app_icon.png`. Merge a second release workflow into one. |
| 4 | About dialog, licenses page, macOS menu | `about-dialog.md`, `licensing.md` | **Needs minimum l10n** (area 6's `l10n.yaml`, common ARB keys, `localeResolutionCallback`) because the common dialog uses `AppLocalizations`. Port the app's tagline/description/features into ARB; drop outdated text. App-specific About code goes in `lib/about/<app>_about.dart`, not into the copied file. Wrap the app in `AppMenuBar` for the macOS menu item. |
| 5 | Icons | `icons.md` | Needs the original glyph — ask for it rather than tracing the finished icon. Delete unused icons8 assets the audit lists. |
| 6 | l10n, theme, fonts, window | `localization.md`, `theming.md`, `fonts.md`, `ui-ux.md` | Use `common/lib/settings/` and `common/lib/theme/`. **Changing a prefs key loses settings** — pass the old key: `AppSettings.load(legacyKeys: {'locale': AppSettings.localeKey})`. Moving many hardcoded strings (`l10n.hardcoded`) is large: offer its own PR. Dark-only apps: ask before adding light. Dropping SeoulNamsan 300 is visible — ask. |
| 7 | README | `readme-guide.md` | `init_readme.py --force`, then move the old developer notes into `## Development` or `docs/` — don't delete them. Placeholders cover screenshots until `capture.sh` (needs Screen Recording permission). |
| 8 | CLAUDE.md | `conventions/README.md` step 10 | Record `conventions-v1`, plus `(미적용: …)` for areas not done. |

## 3. Apply

Work on a branch (`conventions-v1`). For each chosen area:

1. Read the area's convention doc and the matching files in `$T/common`,
   `$T/desktop` or `$T/mobile`.
2. Make the change; keep app-specific behavior the templates don't cover.
3. After ARB edits run `flutter gen-l10n`; then `flutter analyze` and
   `flutter test --reporter=failures-only`; re-run `audit_app.py` and see the
   area go green. On macOS, after identity or menu changes, also
   `flutter build macos --debug`.
4. Commit it on its own with a Korean Conventional Commit
   (`fix(identity): 저작권자·게시자를 Jongyun Ahn으로 통일`,
   `ci: 릴리스 워크플로를 conventions-v1 템플릿으로 교체`), so each area can be
   reviewed or reverted alone.

If an area needs something only the user has (glyph, a design decision,
screen recording permission, the official font license text), skip or use the
stopgap above, keep going, and list it.

## 4. Report and hand off

```
## <App> 규약 적용 결과: ❌ 20 → 6 (🛑 6 → 0) · ⚠️ 4 → 2 · ✅ 8 → 24

| 영역 | 커밋 | 결과 |
### 사용자에게 보이는 변화 (산출물 이름, 설치 프로그램, 정보 창 …)
### 남은 항목 (사용자 필요)
```

(🛑 counts are a subset of ❌.) Pushing the branch and opening the PR are
outward-facing: ask first. Don't tag from this skill — once the PR is merged,
suggest the `flutter-app-release-check` skill; if the release workflow
changed, suggest a manual build run first.
