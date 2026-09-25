---
name: flutter-app-release-check
description: Pre-release go/no-go check for a Flutter app that follows jejezz/application-release-templates — the "앱 릴리즈 직전 단계 확인". Verifies version bump vs last tag, unpushed work, tag/pubspec match, release workflow, installers, translations, README, tests and GitHub secrets, proposes the next version from the actual changes, then guides bump → PR → tag. Use this whenever the user is about to ship or tag ("릴리즈 해도 돼?", "배포 전에 확인해줘", "v1.2.0 태그 달자", "release 준비", "버전 올리고 배포", "ready to release?", "cut a release") — even if they only say they want to bump the version or push a tag.
---

# Release check (앱 릴리즈 직전 단계 확인)

A release tag triggers CI that builds, signs and publishes to GitHub Releases
(desktop) or TestFlight / Play (mobile). A bad tag is expensive: published
assets can't be quietly replaced and tags must not be moved
(`conventions/tagging.md` §2). This skill finds what would make the release
fail or ship wrong **before** the tag, then walks the user through
bump → merge → tag.

## 0. Find the conventions and the app

```bash
T=$(cd "<this skill's base directory>" && git rev-parse --show-toplevel)
git -C "$T" pull --ff-only --quiet || echo "could not update $T — using the checked-out version"
```

The app is the current working directory unless the user named another. If
`pubspec.yaml` is in a subfolder (e.g. `gui/` beside a Rust crate), use that
folder as `<app>`; git commands still run at the repository root, and the
audit reads repository-level files (`.github/`, `LICENSE`, `CLAUDE.md`,
`README*.md`, `scripts/`, `installer/`, `tool/readme/`) from there.

## 1. Run the checks

Fetch first, so every later git answer is about the current remote:

```bash
git fetch --tags --quiet origin
python3 "$T/tools/audit_app.py" <app> --stage release --json
```

`--stage release` checks everything — including a **finished README** (no
TODOs, real screenshots; placeholders are warnings) — and adds release readiness (clean tree, branch, commits not on
origin, version bumped, tag free, and GitHub secrets vs what the workflows
use). The JSON has `verdict` (`go` · `bump` · `hold`) and per check
`blocks_release` / `needed_for_upgrade`:

- 🛑 `blocks_release` — breaks this release with the workflow the app has
  **now** (the check job rejects the tag, a secret is missing, users would
  get a wrong version or missing artifacts). These decide the verdict.
- ⤴ `needed_for_upgrade` — only matters once the app moves to the
  conventions-v1 workflow. Not a blocker today; mention it as a bundle.
- Other ❌/⚠️ — convention debt. List briefly; suggest the
  `flutter-app-convention-audit` skill after the release.

Then, in parallel:

```bash
flutter analyze
flutter test --reporter=failures-only
LAST=$(git describe --tags --abbrev=0 2>/dev/null)
git log --oneline "$LAST"..origin/main ; git log --oneline "$LAST"..HEAD
git diff --stat "$LAST"..HEAD -- lib assets pubspec.yaml
gh run list --workflow release.yml -L 3          # release-ios.yml / release-android.yml for mobile
```

A failing test or analyzer error blocks the release.

A pre-release tag (`vX.Y.Z-rc.N`) is judged the same way, except that CI
checks only the README's structure for it (`readme-guide.md` "단계별 기준") —
so for a pre-release, README content TODOs are not blockers; say so in the
report.

## 2. Decide the version

Only when the verdict is `bump` or the version needs choosing. Read the
commits **and** the diff — a commit message can promise a feature the diff
doesn't contain; if they disagree, say so and ask before choosing.

| Changes since the last tag | ≥ 1.0.0 | < 1.0.0 |
|---|---|---|
| breaking: settings/data incompatibility, removed feature, relearn UI | major | minor |
| any `feat` (user-visible new capability) | minor | minor |
| only `fix` / `perf` / `refactor` / `docs` / `chore` | patch | patch |
| nothing user-visible at all | ask whether to release | ask |
| pubspec is a pre-release (`0.1.0-rc.1`) and this is the real release | `bump-version.sh patch` → `0.1.0` | same |

Show the commit list that justifies the choice and let the user pick.

## 3. Report

Verdict first, then evidence. Keep "passing" to one line.

```
## 릴리스 판정: 🛑 보류 | 🟡 버전만 올리면 진행 가능 | ✅ 진행 가능

다음 버전: v1.4.0 (현재 1.3.2+41 → 1.4.0+42) — feat 3건, fix 5건

### 🛑 이번 릴리스를 막는 문제
| 항목 | 내용 | 해결 |
### ⤴ 워크플로를 conventions-v1으로 올릴 때 함께 할 것
### ⚠️ 릴리스 후 정리할 규약 부채 (한 줄씩)
### ✅ 통과
analyze · test 289 · 번역 · README · 시크릿 6/6 · 최근 CI 성공
```

## 4. Fix and ship

- Offer to fix blocking items that are local and mechanical: missing
  translations, README TODOs, a copied template file. Never change a released
  bundle id / applicationId / Windows `AppId` (`identity.md` §5).
- **Local commits not on origin** (`release.up-to-date`): keep them by moving
  them to the release branch, not by pushing to `main`:
  ```bash
  git switch -c release/v1.4.0          # takes the local commits along
  git branch -f main origin/main
  ```
- **Bump** on the release branch:
  ```bash
  git switch -c release/v1.4.0          # if not already on it
  scripts/bump-version.sh minor         # commits "chore(release): v1.4.0"
  ```
  If `scripts/bump-version.sh` is missing, copy it from
  `$T/common/scripts/` in the same PR (it's part of the conventions).
- Pushing the branch and opening the PR are outward-facing: ask first.
- Desktop apps can prove the build before tagging with a manual run —
  `gh workflow run release.yml --ref release/v1.4.0` builds every platform
  and never publishes (`tagging.md` §3). Offer it when the workflow, native
  dependencies or Flutter version changed since the last release; ask before
  running it.
- After the PR merges, tag `main`:
  ```bash
  git switch main && git pull --ff-only
  git tag -a v1.4.0 -m "<Display Name> 1.4.0"
  git push origin v1.4.0
  ```
  If `pull --ff-only` refuses (e.g. the PR was squash-merged and local `main`
  had other commits), reset to `origin/main` after confirming nothing local
  is lost. Pushing the tag publishes the release: get an explicit "yes" for
  this exact tag right before pushing, then `gh run watch` and report the
  outcome with the release URL.
