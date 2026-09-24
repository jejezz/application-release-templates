---
name: flutter-app-convention-audit
description: Audit an existing (older) Flutter app against the shared conventions in jejezz/application-release-templates and bring it up to date — the "구형 앱 확인 및 수정". Reports every gap (identity, versioning, release workflow, installers, About dialog, icons, license, l10n, theme, fonts, README, CLAUDE.md), plans the fixes by risk, and applies them area by area on a branch without breaking released identifiers or user settings. Use this whenever the user wants to check or modernize an app that predates the conventions ("이 앱 규약에 맞는지 봐줘", "옛날 앱 정리", "템플릿 최신으로 맞춰줘", "conventions 적용", "portside 업데이트", "audit this app") — or mentions that an app is out of date with the others.
---

# Convention audit & fix (구형 앱 확인 및 수정)

Apps written before the conventions each solved release, About, icons, l10n
and so on their own way. This skill measures the gap, fixes it in a safe order
and leaves the app indistinguishable from a freshly bootstrapped one — without
breaking what existing users already have: installed apps must still upgrade,
and saved settings must survive.

## 0. Find the conventions and sync the app

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only || echo "templates repo has local changes — using as is"
```

Local checkouts of these apps are often behind `origin` (several were 6–17
commits behind when the conventions were written). Audit what's really there:

```bash
git fetch --tags origin
git status -sb                 # behind? local changes? unpushed commits?
```

If the branch is only behind, `git pull --ff-only`. If there are local changes
or unpushed commits, stop and show them — they're the user's work in progress.
Also note any tag that isn't on `main` (`git branch -a --contains <tag>`): a
release built from an unmerged branch means `main` is behind what users run.

## 1. Audit

```bash
python3 "$T/tools/audit_app.py" <app>          # add --json if you want to parse it
```

Read the app's row in `$T/conventions/survey-2026-09.md` ("규약 적용 시 앱별
할 일") too — it records app-specific findings the script can't see (e.g.
"'macOS 전용' 문구가 정보 창에 남아 있음").

## 2. Plan by risk, then ask

Group the gaps into the work order below and mark each item's risk. Show the
plan as a table (area · what changes · risk · effort) and ask which areas to
do now (AskUserQuestion, multi-select; default: all). Don't start editing
before the answer.

| # | Area | Convention | Watch out for |
|---|---|---|---|
| 1 | Identity strings, LICENSE | `identity.md`, `licensing.md` | **Never change a released bundle id / applicationId / Windows `AppId`** — installed copies would stop upgrading. Only display strings (copyright, publisher, CompanyName) change. |
| 2 | Version sync | `versioning.md`, `tagging.md` | Bring `main` up to the latest tag by merging, never by moving/deleting tags. Remove hardcoded version strings (use `package_info_plus`). |
| 3 | Release workflow, installers | `workflow.md`, `packaging.md` | When replacing `release.yml`, keep the app's own build steps (brew/apt packages, Rust toolchain, extra artifacts). Keep the existing `AppId` GUID when updating the `.iss`. Merge a second release workflow into one. |
| 4 | About dialog, licenses page | `about-dialog.md`, `licensing.md` | Port the app's existing tagline/description/features into l10n strings; drop outdated text. |
| 5 | Icons | `icons.md` | Needs the original glyph. If only the finished icon exists, ask for the glyph (Icons8) rather than guessing. |
| 6 | l10n, theme, fonts, window | `localization.md`, `theming.md`, `fonts.md`, `ui-ux.md` | **Changing a prefs key loses users' settings** — read the old key once, write the new one, delete the old (migration). Moving hardcoded strings into ARB is large for some apps; offer to split it into its own PR. |
| 7 | README | `readme-guide.md` | Move developer notes into `## Development` or `docs/` — don't delete them. Screenshots/GIF need the running app (`tool/readme/capture.sh`). |
| 8 | CLAUDE.md | `conventions/README.md` step 10 | Record `conventions-v1`. |

## 3. Apply

Work on a branch (`conventions-v1`). For each chosen area:

1. Read that area's convention doc and the matching template in `$T/common`,
   `$T/desktop` or `$T/mobile`.
2. Make the change; keep app-specific behavior the templates don't cover.
3. `flutter analyze` (and `flutter test` when code changed), then re-run
   `audit_app.py` to see the area go green.
4. Commit it on its own (`fix(identity): …`, `ci: update release workflow to conventions-v1`,
   `feat(l10n): …`) so the user can review or revert one area at a time.

If an area needs something only the user has (glyph file, a decision about a
dark-only app, screen recording permission), skip it, keep going, and list it.

## 4. Report and hand off

```
## <App> 규약 적용 결과: ❌ 20 → 2 · ⚠️ 6 → 3

| 영역 | 커밋 | 결과 |
### 남은 항목 (사용자 필요)
- 앱 아이콘 원본 글리프 — assets/icon/source_glyph.png
- README 스크린샷·데모 GIF — tool/readme/capture.sh (화면 기록 권한)
```

Pushing the branch and opening the PR are outward-facing: ask first. Don't
tag a release from this skill — once the PR is merged, suggest running the
`flutter-app-release-check` skill.
