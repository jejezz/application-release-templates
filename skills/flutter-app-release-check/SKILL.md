---
name: flutter-app-release-check
description: Pre-release go/no-go check for a Flutter app that follows jejezz/application-release-templates — the "앱 릴리즈 직전 단계 확인". Verifies version bump vs last tag, tag/pubspec match, release workflow, installers, translations, README, tests and secrets, then guides the version bump and tag. Use this whenever the user is about to ship or tag ("릴리즈 해도 돼?", "배포 전에 확인해줘", "v1.2.0 태그 달자", "release 준비", "버전 올리고 배포", "ready to release?", "cut a release") — even if they only say they want to bump the version or push a tag.
---

# Release check (앱 릴리즈 직전 단계 확인)

A release tag triggers CI that builds, signs and publishes to GitHub Releases
(desktop) or TestFlight / Play (mobile). A bad tag is expensive: published
assets can't be quietly replaced and tags must not be moved
(`conventions/tagging.md` §2). This skill finds everything that would make the
release fail or ship wrong **before** the tag, then walks the user through
bump → merge → tag.

## 0. Find the conventions and the app

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only || echo "templates repo has local changes — using as is"
```

The app is the current working directory unless the user named another. If
`pubspec.yaml` is in a subfolder (e.g. `gui/` beside a Rust crate), audit that
folder.

## 1. Run the checks

Run these; they're independent, so run them in parallel where possible:

```bash
python3 "$T/tools/audit_app.py" <app> --release      # conventions + release readiness (runs git fetch)
flutter analyze
flutter test
python3 tool/readme/check_readme.py                   # if present
gh secret list                                        # names only
gh run list --workflow release.yml -L 3               # desktop; release-ios/android.yml for mobile
git log --oneline $(git describe --tags --abbrev=0)..HEAD
```

`audit_app.py` marks failures that would break the release with 🛑
(`blocks_release` in `--json`): the workflow's check job would reject them, or
the artifacts would come out wrong. Other ❌/⚠️ are convention debt — worth
fixing, but not a reason to hold a release.

Compare `gh secret list` with the secrets the workflows reference (tables in
`$T/desktop/README.md`, `$T/mobile/README.md`). A missing macOS signing secret
fails the build midway, so it blocks.

## 2. Decide the version

If `release.version-bumped` failed (pubspec equals the last tag), propose the
bump from the commits since the last tag — they follow Conventional Commits
(`tagging.md` §4): any `feat` → minor, only `fix`/`chore`/`docs` → patch,
anything marked breaking (or data/settings incompatibility) → major
(`versioning.md` §2). Before 1.0.0, breaking changes bump the minor. Show the
commit list that justifies it and let the user choose.

## 3. Report

Give a verdict first, then the evidence:

```
## 릴리스 판정: 🛑 보류 | ✅ 진행 가능

다음 버전: v1.4.0 (현재 1.3.2+41 → 1.4.0+42) — feat 3건, fix 5건

### 🛑 릴리스를 막는 문제
| 항목 | 내용 | 해결 |
### ⚠️ 릴리스 후 정리할 규약 부채
| 항목 | 내용 | 해결 |
### ✅ 통과
analyze · test · 번역 · README · 시크릿 · 최근 CI …
```

Keep the passing list to one line; the user cares about what's wrong.

## 4. Fix and ship

- Offer to fix the blocking items that are local and mechanical (copy a newer
  template file, add missing translations, fill README TODOs, fix a copyright
  string). Anything touching identifiers or the Windows `AppId` is never
  "fixed" on a released app — `identity.md` §5 explains why.
- Bump with the script, on a branch, and open a PR:
  ```bash
  git switch -c release/v1.4.0
  scripts/bump-version.sh minor        # commits chore(release): v1.4.0
  ```
  Pushing the branch and opening the PR are outward-facing: ask first.
- Desktop apps can prove the build before tagging by running the release
  workflow manually (`gh workflow run release.yml --ref <branch>`) — it
  builds all platforms but never publishes (`tagging.md` §3). Offer it when
  the workflow or native dependencies changed since the last release.
- After the PR merges, the tag goes on `main`:
  ```bash
  git switch main && git pull
  git tag -a v1.4.0 -m "<Display Name> 1.4.0"
  git push origin v1.4.0
  ```
  Pushing the tag publishes the release. Always get an explicit "yes" for this
  exact tag right before pushing it, then watch the run
  (`gh run watch`) and report the result with the release URL.
