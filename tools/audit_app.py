#!/usr/bin/env python3
"""Audit a Flutter app against conventions/ (read-only).

    python3 tools/audit_app.py <app-dir> --stage bootstrap   # 앱 구현 전
    python3 tools/audit_app.py <app-dir> --stage release     # 릴리스 직전 (+ git, secrets, verdict)
    python3 tools/audit_app.py <app-dir> [--stage maintain]  # 기존 앱 정비 (default)
    … --json                                                 # for scripts / skills

Stages check different things (skills/README.md has the full table):

  bootstrap  the foundation before any feature exists. README is checked for
             structure only (features, screenshots and demo come later);
             hardcoded strings and release readiness are not checked. Goal: 0 ❌.
  release    everything, README complete, plus release readiness (clean tree,
             commits on origin, version bumped, tag free, secrets) and a
             verdict: go · bump · hold.
  maintain   everything except release readiness — the full debt list.

Every check has an id, an area, a status and a fix hint pointing at the
convention that defines it:

  pass   follows the convention
  warn   differs, but is allowed or cosmetic (e.g. a legacy bundle id that
         must not change after release)
  fail   must be fixed
  skip   doesn't apply to this app (no such platform, no l10n yet, …)

A failing check that breaks a release with the workflow the app has *now*
(its check job rejects the tag, or users get wrong artifacts) is marked
blocks_release / 🛑. One that only matters once the app adopts the
conventions-v1 workflow is needed_for_upgrade / ⤴. With --release, a
verdict is added: go · bump (only the version bump is missing) · hold.

Exit status: 1 if any check fails, else 0. The script never modifies the app.
Used by the flutter-app-bootstrap / flutter-app-release-check /
flutter-app-convention-audit skills in skills/.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path

def _conventions_url() -> str:
    """Doc links point at the branch this templates clone is on, if it's on
    GitHub — so links work before a conventions PR is merged."""
    here = Path(__file__).resolve().parent
    try:
        branch = subprocess.run(['git', '-C', str(here), 'rev-parse', '--abbrev-ref', 'HEAD'],
                                capture_output=True, text=True, check=True).stdout.strip()
        remote = subprocess.run(['git', '-C', str(here), 'ls-remote', '--heads', 'origin', branch],
                                capture_output=True, text=True, check=True, timeout=10).stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        branch, remote = 'main', ''
    return f'https://github.com/jejezz/application-release-templates/blob/{branch if remote else "main"}/conventions'


CONVENTIONS = _conventions_url()
PREFIX = 'art.zoomon'
HOLDER = 'Jongyun Ahn'
FLUTTER_VERSION = '3.47.1'


@dataclass
class Check:
    id: str
    area: str
    status: str
    message: str
    fix: str = ''
    doc: str = ''
    blocks_release: bool = False
    # Fails only once the app moves to the conventions-v1 release workflow
    # (e.g. the new workflow expects linux/install.sh); harmless before.
    needed_for_upgrade: bool = False


class Audit:
    def __init__(self, root: Path, stage: str):
        self.root = root
        self.stage = stage
        self.release = stage == 'release'
        self.bootstrap = stage == 'bootstrap'
        self.checks: list[Check] = []
        self.platforms = [p for p in ('macos', 'windows', 'linux', 'ios', 'android') if (root / p).is_dir()]
        self.desktop = [p for p in self.platforms if p in ('macos', 'windows', 'linux')]
        self.mobile = [p for p in self.platforms if p in ('ios', 'android')]
        rel = self.read('.github/workflows/release.yml')
        # Does the app already run the conventions-v1 desktop workflow? Several
        # checks only break a release under it.
        self.modern = bool(re.search(r'^\s{2}check:\s*$', rel, re.M)) and 'macos-universal.dmg' in rel

    # -- helpers -----------------------------------------------------------
    def read(self, rel: str) -> str:
        p = self.root / rel
        try:
            return p.read_text(encoding='utf-8', errors='replace') if p.is_file() else ''
        except OSError:
            return ''

    def exists(self, rel: str) -> bool:
        return (self.root / rel).exists()

    def lib_dart(self) -> str:
        if not hasattr(self, '_lib'):
            parts = []
            for p in (self.root / 'lib').rglob('*.dart') if (self.root / 'lib').is_dir() else []:
                if '/l10n/app_localizations' in str(p) or p.name.endswith('.g.dart'):
                    continue
                code = p.read_text(encoding='utf-8', errors='replace')
                # Match code, not comments ("// no localeResolutionCallback yet"
                # must not count as having one).
                code = re.sub(r'/\*.*?\*/', '', code, flags=re.S)
                code = re.sub(r'(?m)^\s*///?.*$|(?<=[;{}),])\s*//.*$', '', code)
                parts.append(f'// FILE {p.relative_to(self.root)}\n' + code)
            self._lib = '\n'.join(parts)
        return self._lib

    def git(self, *args: str) -> str:
        try:
            return subprocess.run(['git', '-C', str(self.root), *args], capture_output=True,
                                  text=True, check=True).stdout.strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            return ''

    def add(self, id: str, area: str, status: str, message: str, fix: str = '', doc: str = '',
            blocks: bool = False, upgrade: bool = False) -> None:
        """blocks: a failure here breaks the release with the workflow the app
        has *now* — its check job rejects the tag, or users get wrong artifacts.
        upgrade: only matters once the app adopts the conventions-v1 workflow."""
        failing = status == 'fail'
        self.checks.append(Check(id, area, status, message, fix, f'{CONVENTIONS}/{doc}' if doc else '',
                                 failing and blocks, failing and upgrade and not blocks))

    # -- values ------------------------------------------------------------
    def product_name(self) -> str:
        m = re.search(r'^PRODUCT_NAME\s*=\s*(.+)$', self.read('macos/Runner/Configs/AppInfo.xcconfig'), re.M)
        return m.group(1).strip() if m else ''

    def pubspec_version(self) -> str:
        m = re.search(r'^version:\s*(\S+)', self.read('pubspec.yaml'), re.M)
        return m.group(1) if m else ''

    def latest_tag(self) -> str:
        tags = self.git('tag', '--list', 'v*', '--sort=-v:refname').splitlines()
        return tags[0] if tags else ''

    # -- areas -------------------------------------------------------------
    def identity(self) -> None:
        a, doc = 'identity', 'identity.md'
        ids = {}
        xc = self.read('macos/Runner/Configs/AppInfo.xcconfig')
        if m := re.search(r'^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)', xc, re.M):
            ids['macOS'] = m.group(1)
        if m := re.search(r'PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);', self.read('ios/Runner.xcodeproj/project.pbxproj')):
            ids['iOS'] = m.group(1)
        gradle = self.read('android/app/build.gradle.kts') or self.read('android/app/build.gradle')
        if m := re.search(r'applicationId\s*=?\s*"([^"]+)"', gradle):
            ids['Android'] = m.group(1)
        if m := re.search(r'set\(APPLICATION_ID "([^"]+)"\)', self.read('linux/CMakeLists.txt')):
            ids['Linux'] = m.group(1)

        if any(v.startswith('com.example') for v in ids.values()):
            bad = ', '.join(f'{k}={v}' for k, v in ids.items() if v.startswith('com.example'))
            self.add('identity.no-com-example', a, 'fail', f'default identifier left: {bad}',
                     f'set every identifier to {PREFIX}.<name> (before the first release)', doc, blocks=True)
        elif ids:
            self.add('identity.no-com-example', a, 'pass', 'no com.example identifiers')

        if len(set(ids.values())) > 1:
            self.add('identity.ids-equal', a, 'warn',
                     'identifiers differ per platform: ' + ', '.join(f'{k}={v}' for k, v in ids.items()),
                     'unify before the first release; after a release only change unreleased platforms', doc)
        elif ids:
            self.add('identity.ids-equal', a, 'pass', f'one identifier everywhere: {next(iter(ids.values()))}')

        if ids and not all(v.startswith(PREFIX + '.') for v in ids.values()):
            self.add('identity.prefix', a, 'warn', f'identifier prefix is not {PREFIX}',
                     'keep it if already released (changing it makes a different app); else switch', doc)
        elif ids:
            self.add('identity.prefix', a, 'pass', f'prefix {PREFIX}')

        if 'macos' in self.platforms:
            if self.product_name():
                self.add('identity.product-name', a, 'pass', f'display name "{self.product_name()}"')
            else:
                self.add('identity.product-name', a, 'fail', 'PRODUCT_NAME missing in AppInfo.xcconfig',
                         'set PRODUCT_NAME to the display name', doc, blocks=self.modern, upgrade=True)

        pbx = self.read('macos/Runner.xcodeproj/project.pbxproj')
        m = re.search(r'TEST_HOST = "\$\(BUILT_PRODUCTS_DIR\)/([^"/]+)\.app/', pbx)
        if m and self.product_name() and m.group(1) != self.product_name():
            self.add('identity.test-host', a, 'fail',
                     f'macOS RunnerTests TEST_HOST points at "{m.group(1)}.app", the app is "{self.product_name()}.app"',
                     'update TEST_HOST (all 3 build configs) in macos/Runner.xcodeproj/project.pbxproj after renaming', doc)
        ident = self.read('lib/app_identity.dart')
        if not ident:
            self.add('identity.app-identity', a, 'fail', 'lib/app_identity.dart missing',
                     'copy common/lib/app_identity.dart and fill it', doc)
        elif '__' in ident:
            self.add('identity.app-identity', a, 'fail', 'lib/app_identity.dart still has __PLACEHOLDERS__',
                     'fill displayName and repositoryUrl', doc, blocks=True)
        elif self.product_name() and f"displayName = '{self.product_name()}'" not in ident:
            # The v1 check job compares them only when the file exists.
            self.add('identity.app-identity', a, 'fail', 'AppIdentity.displayName != PRODUCT_NAME',
                     'make them identical (the desktop check job compares them)', doc, blocks=self.modern, upgrade=True)
        else:
            self.add('identity.app-identity', a, 'pass', 'lib/app_identity.dart filled')

        copyright_re = re.compile(r'Copyright (?:©|\(C\)) \d{4} ' + re.escape(HOLDER) + r'\.?\s*$')
        for rel, pattern in (('macos/Runner/Configs/AppInfo.xcconfig', r'^PRODUCT_COPYRIGHT\s*=\s*(.+)$'),
                             ('windows/runner/Runner.rc', r'VALUE "LegalCopyright", "([^"]+)"')):
            text = self.read(rel)
            if not text:
                continue
            m = re.search(pattern, text, re.M)
            value = m.group(1).strip() if m else ''
            if value and copyright_re.match(value):
                self.add(f'identity.copyright.{rel.split("/")[0]}', a, 'pass', f'{rel}: {value}')
            else:
                self.add(f'identity.copyright.{rel.split("/")[0]}', a, 'fail', f'{rel}: "{value or "missing"}"',
                         f'"Copyright © <year> {HOLDER}" (Windows: (C)), no "All rights reserved"', doc)
        rc = self.read('windows/runner/Runner.rc')
        if rc:
            m = re.search(r'VALUE "CompanyName", "([^"]+)"', rc)
            ok = m and m.group(1) == HOLDER
            self.add('identity.company', a, 'pass' if ok else 'fail',
                     f'Runner.rc CompanyName "{m.group(1) if m else "missing"}"',
                     '' if ok else f'CompanyName "{HOLDER}"', doc)

    def versioning(self) -> None:
        a, doc = 'versioning', 'versioning.md'
        v = self.pubspec_version()
        m = re.fullmatch(r'(\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)\+(\d+)', v)
        if not m:
            self.add('version.format', a, 'fail', f'pubspec version "{v}" is not X.Y.Z+BUILD',
                     'e.g. version: 0.1.0+1', doc, blocks=True)
            return
        name, build = m.group(1), int(m.group(2))
        self.add('version.format', a, 'pass', f'pubspec {v}')
        if self.bootstrap and not self.latest_tag() and not name.startswith('0.1.0'):
            self.add('version.first', a, 'warn', f'first version is {name}',
                     'start at 0.1.0-rc.1+1 (desktop) / 0.1.0+1 (mobile)', doc)

        tag = self.latest_tag()
        if tag:
            tag_ver = tag[1:]
            tag_pubspec = self.git('show', f'{tag}:pubspec.yaml')
            tm = re.search(r'^version:\s*\S+\+(\d+)', tag_pubspec, re.M)
            if self._semver(name) < self._semver(tag_ver):
                self.add('version.not-behind-tag', a, 'fail', f'pubspec {name} is behind latest tag {tag}',
                         'the tag was made on another branch or the bump never merged — merge that work into main '
                         '(never move or delete the tag)', doc, blocks=True)
            else:
                self.add('version.not-behind-tag', a, 'pass', f'latest tag {tag}')
            if tm and build < int(tm.group(1)):
                self.add('version.build-monotonic', a, 'fail',
                         f'build {build} is lower than {tag}\'s build {tm.group(1)}', 'build number only goes up', doc, blocks=True)
            elif tm:
                self.add('version.build-monotonic', a, 'pass', f'build {build} ≥ {tag}\'s {tm.group(1)}')
        hard = re.findall(r"(?:version|kAppVersion|appVersion)\w*\s*=\s*'(\d+\.\d+\.\d+)'", self.lib_dart())
        if hard:
            # The About dialog would show users a wrong version.
            self.add('version.not-hardcoded', a, 'fail', f'version hardcoded in lib/: {", ".join(sorted(set(hard)))}',
                     'read it with package_info_plus', doc, blocks=True)
        else:
            self.add('version.not-hardcoded', a, 'pass', 'no hardcoded version in lib/')
        # Cargo.toml next to pubspec.yaml, or at the repository root when the
        # Flutter app lives in a subfolder (allwinner-phoenix: gui/).
        cargo = self.read('Cargo.toml')
        top = self.git('rev-parse', '--show-toplevel')
        if not cargo and top and Path(top).resolve() != self.root:
            p = Path(top) / 'Cargo.toml'
            cargo = p.read_text(encoding='utf-8') if p.exists() else ''
        if cargo:
            cm = re.search(r'^version\s*=\s*"([^"]+)"', cargo, re.M)
            ok = cm and cm.group(1) == name
            self.add('version.cargo', a, 'pass' if ok else 'fail',
                     f'Cargo.toml {cm.group(1) if cm else "?"} vs pubspec {name}', '' if ok else 'bump together', doc, blocks=True)
        if not self.exists('scripts/bump-version.sh'):
            self.add('version.bump-script', a, 'warn', 'scripts/bump-version.sh missing',
                     'copy common/scripts/bump-version.sh', doc)
        else:
            self.add('version.bump-script', a, 'pass', 'scripts/bump-version.sh present')

    @staticmethod
    def _semver(v: str) -> tuple:
        core, _, pre = v.partition('-')
        nums = tuple(int(x) for x in core.split('.')[:3])
        return nums + ((1,) if not pre else (0, pre))

    def workflow(self) -> None:
        a, doc = 'workflow', 'workflow.md'
        wf = self.root / '.github/workflows'
        files = {p.name: p.read_text(encoding='utf-8', errors='replace') for p in wf.glob('*.y*ml')} if wf.is_dir() else {}
        if self.desktop:
            rel = files.get('release.yml', '')
            if not rel:
                self.add('workflow.desktop', a, 'fail', '.github/workflows/release.yml missing — a tag builds nothing',
                         'copy desktop/.github/workflows/release.yml', doc, blocks=True)
            else:
                checks = {
                    'check job (tag/pubspec/l10n)': re.search(r'^\s{2}check:\s*$', rel, re.M),
                    f'FLUTTER_VERSION pinned': 'FLUTTER_VERSION' in rel,
                    'artifact naming <FileName>-<version>-<os>-<arch>': 'macos-universal.dmg' in rel,
                    'SHA256SUMS': 'SHA256SUMS' in rel,
                    'release only on tags': "github.ref_type == 'tag'" in rel,
                }
                missing = [k for k, ok in checks.items() if not ok]
                if missing:
                    # The old workflow still releases — upgrading is debt, and it
                    # pulls in the 'upgrade' items (installer, install.sh, icons).
                    self.add('workflow.desktop', a, 'fail', 'release.yml is an older template (still releases): missing ' + '; '.join(missing),
                             'replace with desktop/.github/workflows/release.yml (keep app-specific build steps); '
                             'fix the items marked "업그레이드 시 필요" in the same PR', doc)
                else:
                    self.add('workflow.desktop', a, 'pass', 'release.yml matches the conventions-v1 template')
                pin = re.search(r'FLUTTER_VERSION:\s*"([^"]+)"', rel)
                if pin and pin.group(1) != FLUTTER_VERSION:
                    self.add('workflow.flutter-version', a, 'warn',
                             f'FLUTTER_VERSION {pin.group(1)} (template: {FLUTTER_VERSION})', 'bump in a PR if intended', doc)
            header = self.read('.github/release-notes-header.md')
            if '__MIN_MACOS__' in header:
                self.add('workflow.notes-header', a, 'fail', 'release-notes-header.md still has __MIN_MACOS__',
                         'set it to MACOSX_DEPLOYMENT_TARGET from macos/Runner.xcodeproj/project.pbxproj', doc,
                         blocks=self.modern, upgrade=True)
            other = [n for n in files if n not in ('release.yml', 'release-ios.yml', 'release-android.yml')]
            if other:
                self.add('workflow.extra', a, 'warn', 'other workflows: ' + ', '.join(sorted(other)),
                         'fine for CI/tests; a second release workflow should be merged into release.yml', doc)
        if self.mobile:
            for name, plat in (('release-ios.yml', 'ios'), ('release-android.yml', 'android')):
                if plat not in self.platforms:
                    continue
                text = files.get(name, '')
                if not text:
                    self.add(f'workflow.{plat}', a, 'fail', f'{name} missing — a tag uploads nothing',
                             'copy mobile/.github/workflows/', doc, blocks=True)
                elif 'check-version' not in text or 'FLUTTER_VERSION' not in text:
                    self.add(f'workflow.{plat}', a, 'fail', f'{name} lacks check-version / FLUTTER_VERSION',
                             'update from mobile/.github/workflows/', doc)
                else:
                    self.add(f'workflow.{plat}', a, 'pass', f'{name} matches the template')

    def packaging(self) -> None:
        a, doc = 'packaging', 'packaging.md'
        if 'windows' in self.platforms:
            iss_files = [p for p in self.root.rglob('*.iss') if 'build' not in p.relative_to(self.root).parts]
            iss = iss_files[0].read_text(encoding='utf-8', errors='replace') if iss_files else ''
            if iss_files and iss_files[0].relative_to(self.root).as_posix() != 'installer/windows/app.iss':
                self.add('packaging.iss-path', a, 'warn', f'installer at {iss_files[0].relative_to(self.root)}',
                         'move to installer/windows/app.iss (the release workflow expects it there)', doc)
            if not iss:
                self.add('packaging.iss', a, 'fail', 'no Inno Setup script', 'copy desktop/installer/windows/app.iss', doc,
                         blocks=self.modern, upgrade=True)
            else:
                problems = []
                if '__REPLACE_WITH_A_FRESH_GUID__' in iss or not re.search(r'AppId=\{\{[0-9A-Fa-f-]{36}', iss):
                    problems.append('AppId GUID not set')
                if '__REPOSITORY__' in iss:
                    problems.append('MyAppURL not set')
                if HOLDER not in iss:
                    problems.append(f'publisher is not {HOLDER}')
                if 'windows-x64-setup' not in iss:
                    problems.append('old OutputBaseFilename')
                if 'Korean.isl' not in iss:
                    problems.append('no Korean installer language')
                self.add('packaging.iss', a, 'fail' if problems else 'pass',
                         'installer: ' + ('; '.join(problems) if problems else 'matches the template'),
                         'update from desktop/installer/windows/app.iss — keep the existing AppId GUID' if problems else '', doc,
                         blocks=self.modern and 'windows-x64-setup' not in iss, upgrade=True)
            if any(p.suffix == '.wxs' for p in self.root.rglob('*.wxs')):
                self.add('packaging.no-wix', a, 'warn', 'WiX .wxs file present', 'Inno Setup only — delete the .wxs', doc)
        if 'linux' in self.platforms:
            ok = self.exists('linux/install.sh')
            self.add('packaging.linux-install', a, 'pass' if ok else 'fail',
                     'linux/install.sh ' + ('present' if ok else 'missing'), '' if ok else 'copy desktop/linux/install.sh', doc,
                     blocks=self.modern, upgrade=True)
        if self.exists('scripts/release.sh'):
            self.add('packaging.no-local-release', a, 'warn', 'scripts/release.sh (local release script)',
                     'release through CI; keep local scripts as dev builds only', doc)

    def about(self) -> None:
        a, doc = 'about', 'about-dialog.md'
        lib = self.lib_dart()
        if 'showAppAboutDialog' in lib:
            self.add('about.dialog', a, 'pass', 'common about dialog wired')
        elif re.search(r'AboutDialog|showAboutDialog|about_dialog', lib):
            self.add('about.dialog', a, 'fail', 'custom About dialog (not the common one)',
                     'replace with common/lib/about/about_dialog.dart', doc)
        else:
            self.add('about.dialog', a, 'fail', 'no About dialog', 'add common/lib/about/about_dialog.dart', doc)
        if 'package_info_plus' not in self.read('pubspec.yaml'):
            self.add('about.package-info', a, 'fail', 'package_info_plus not a dependency',
                     'flutter pub add package_info_plus', doc)
        else:
            self.add('about.package-info', a, 'pass', 'package_info_plus present')
        if 'macos' in self.platforms and 'PlatformMenuBar' not in lib and 'AppMenuBar' not in lib:
            self.add('about.macos-menu', a, 'fail', 'macOS app menu "About" not wired to the About dialog',
                     'wrap the app in common/lib/about/app_menu_bar.dart', doc)
        if 'showLicensePage' in lib or 'showAppAboutDialog' in lib:
            self.add('about.licenses', a, 'pass', 'open-source licenses page reachable')
        else:
            self.add('about.licenses', a, 'fail', 'no open-source licenses page', 'the common about dialog has it', 'licensing.md')

    def icons(self) -> None:
        a, doc = 'icons', 'icons.md'
        glyph = self.exists('assets/icon/source_glyph.png')
        script = self.exists('tool/icon/generate_icons.py')
        if glyph and script:
            self.add('icons.pipeline', a, 'pass', 'glyph + generator present')
        else:
            self.add('icons.pipeline', a, 'fail',
                     'missing: ' + ', '.join(n for n, ok in (('assets/icon/source_glyph.png', glyph),
                                                              ('tool/icon/generate_icons.py', script)) if not ok),
                     'copy common/tool/icon/, put the glyph in assets/icon/, run the generator', doc)
        if not self.exists('assets/icon/app_icon.png'):
            self.add('icons.in-app', a, 'fail', 'assets/icon/app_icon.png missing (About dialog, README)',
                     'run tool/icon/generate_icons.py', doc)
        if 'linux' in self.platforms and not self.exists('linux/runner/resources/app_icon.png'):
            self.add('icons.linux', a, 'fail', 'linux/runner/resources/app_icon.png missing (release tarball needs it)',
                     'run tool/icon/generate_icons.py', doc, blocks=self.modern, upgrade=True)
        unused = [p for p in (self.root / 'assets').rglob('icons8-*') if p.is_file()] if self.exists('assets') else []
        if unused:
            refs = self.lib_dart() + self.read('pubspec.yaml')
            # Referenced by file name, or its folder is declared as an asset dir.
            dead = [p for p in unused if p.name not in refs
                    and f'{p.parent.relative_to(self.root).as_posix()}/' not in refs]
            if dead:
                self.add('icons.unused', a, 'warn', f'{len(dead)} icons8 assets not referenced (e.g. {dead[0].name})',
                         'delete unused assets', doc)

    def licensing(self) -> None:
        a, doc = 'licensing', 'licensing.md'
        lic = self.read('LICENSE')
        if not lic:
            self.add('license.file', a, 'fail', 'LICENSE missing', 'MIT (public) or proprietary one-liner (private)', doc)
        elif 'MIT License' in lic and HOLDER not in lic:
            self.add('license.file', a, 'fail', f'LICENSE holder is not {HOLDER}', f'Copyright (c) <year> {HOLDER}', doc)
        else:
            self.add('license.file', a, 'pass', 'LICENSE ' + ('MIT' if 'MIT License' in lic else 'present'))
        if 'SeoulNamsan' in self.read('pubspec.yaml'):
            ok = self.exists('assets/licenses/seoul-namsan.txt') and 'registerExtraLicenses' in self.lib_dart()
            self.add('license.font', a, 'pass' if ok else 'fail',
                     'SeoulNamsan license ' + ('registered' if ok else 'not registered'),
                     '' if ok else 'assets/licenses/seoul-namsan.txt + registerExtraLicenses() in main()', doc)

    def fonts(self) -> None:
        a, doc = 'fonts', 'fonts.md'
        pub = self.read('pubspec.yaml')
        if 'SeoulNamsan' not in pub:
            self.add('fonts.family', a, 'warn', 'SeoulNamsan not bundled', 'bundle 400/700/800 (unless a macos_ui utility)', doc)
            return
        if re.search(r'weight:\s*300', pub):
            self.add('fonts.weights', a, 'warn', 'SeoulNamsan 300 bundled (~4 MB)', 'bundle 400/700/800 only', doc)
        else:
            self.add('fonts.weights', a, 'pass', 'SeoulNamsan weights ok')
        if 'fontFamilyFallback' in self.lib_dart():
            self.add('fonts.fallback', a, 'pass', 'fontFamilyFallback set')
        else:
            self.add('fonts.fallback', a, 'fail', 'no fontFamilyFallback', 'Apple SD Gothic Neo / Malgun Gothic / Noto Sans CJK KR', doc)

    def localization(self) -> None:
        a, doc = 'l10n', 'localization.md'
        y = self.read('l10n.yaml')
        if not y:
            self.add('l10n.setup', a, 'fail', 'no l10n.yaml (strings hardcoded?)', 'gen-l10n with app_ko.arb template + app_en.arb', doc)
            return
        problems = []
        if 'template-arb-file: app_ko.arb' not in y:
            problems.append('template is not app_ko.arb')
        if 'untranslated-messages-file' not in y:
            problems.append('no untranslated-messages-file — the CI translation check silently passes')
        self.add('l10n.setup', a, 'fail' if problems else 'pass',
                 'l10n.yaml: ' + ('; '.join(problems) if problems else 'ok'), '; '.join(problems), doc)
        arb_dir = self.root / (re.search(r'arb-dir:\s*(\S+)', y).group(1) if re.search(r'arb-dir:\s*(\S+)', y) else 'lib/l10n')
        keys = {}
        for p in arb_dir.glob('app_*.arb') if arb_dir.is_dir() else []:
            try:
                keys[p.stem[4:]] = {k for k in json.loads(p.read_text(encoding='utf-8')) if not k.startswith('@')}
            except json.JSONDecodeError:
                self.add('l10n.arb', a, 'fail', f'{p.name} is not valid JSON', '', doc)
        if 'ko' in keys and 'en' in keys:
            diff = (keys['ko'] - keys['en']) | (keys['en'] - keys['ko'])
            self.add('l10n.parity', a, 'fail' if diff else 'pass',
                     f'{len(diff)} keys missing in ko/en' if diff else f'ko/en both {len(keys["ko"])} keys',
                     'translate every key' if diff else '', doc, blocks=True)
        else:
            self.add('l10n.parity', a, 'fail', f'locales: {", ".join(sorted(keys)) or "none"} (need ko + en)', '', doc)
        lib = self.lib_dart()
        # Korean string literals left in code — l10n.parity only sees what's already in ARB.
        hard = [h for h in re.findall(r"'[^'\n]*[가-힣][^'\n]*'|\"[^\"\n]*[가-힣][^\"\n]*\"", lib)
                if h.strip('\'"') != '한국어']  # language names are written in their own language
        if hard and not self.bootstrap:
            self.add('l10n.hardcoded', a, 'warn', f'{len(hard)} Korean string literals still in lib/ (not in ARB)',
                     'move UI strings into app_ko.arb / app_en.arb', doc)
        self.add('l10n.resolution', a, 'pass' if 'localeResolutionCallback' in lib else 'fail',
                 'localeResolutionCallback ' + ('set' if 'localeResolutionCallback' in lib else 'missing'),
                 '' if 'localeResolutionCallback' in lib else 'non-ko system locales → en', doc)
        if "'app_locale'" in lib or '"app_locale"' in lib:
            self.add('l10n.prefs-key', a, 'pass', "locale saved as 'app_locale'")
        elif re.search(r"['\"](locale|language)['\"]", lib) or 'LanguageSetting' in lib:
            self.add('l10n.prefs-key', a, 'warn', 'locale saved under another key/file', "use prefs key 'app_locale'", doc)

    def theming(self) -> None:
        a, doc = 'theming', 'theming.md'
        lib = self.lib_dart()
        if 'darkTheme:' in lib and 'themeMode:' in lib:
            self.add('theme.modes', a, 'pass', 'light + dark themes with themeMode')
        else:
            self.add('theme.modes', a, 'fail', 'light/dark not both wired (darkTheme + themeMode)',
                     'support system / light / dark', doc)
        if "'theme_mode'" in lib:
            self.add('theme.prefs-key', a, 'pass', "theme saved as 'theme_mode'")
        elif 'ThemeMode.' in lib:
            self.add('theme.prefs-key', a, 'warn', "theme not saved under 'theme_mode'", "prefs key 'theme_mode'", doc)
        if re.search(r'_cycleOrder|\.cycle\(\)', lib):
            self.add('theme.switcher', a, 'warn', 'theme/language switch is a cycle button',
                     'checked popup menu (common/lib/settings/settings_menus.dart)', doc)
        elif 'ThemeMenuButton' in lib or 'CheckedPopupMenuItem' in lib or 'SegmentedButton<ThemeMode>' in lib:
            self.add('theme.switcher', a, 'pass', 'theme switcher is a menu / segmented control')
        if 'ColorScheme.fromSeed' in lib:
            self.add('theme.palette', a, 'warn', 'ColorScheme.fromSeed used', 'Saturn palette ColorScheme', doc)
        if self.desktop and 'setBrightness' not in lib:
            self.add('theme.window-brightness', a, 'warn', 'window title bar brightness not synced',
                     'windowManager.setBrightness on theme change', doc)

    def ui(self) -> None:
        a, doc = 'ui', 'ui-ux.md'
        if not self.desktop:
            return
        lib = self.lib_dart()
        if 'WindowOptions' in lib:
            m = re.search(r'minimumSize:\s*Size\(\s*([\d.]+)\s*,\s*([\d.]+)', lib)
            if m and (float(m.group(1)) > 960 or float(m.group(2)) > 600):
                self.add('ui.window', a, 'warn', f'minimumSize {m.group(1)}×{m.group(2)} > 960×600', 'fit 1366×768', doc)
            else:
                self.add('ui.window', a, 'pass', 'window_manager WindowOptions')
        else:
            self.add('ui.window', a, 'fail', 'window size not set with window_manager', 'WindowOptions(size, minimumSize, title)', doc)
        if 'useMaterial3: false' in lib:
            self.add('ui.material3', a, 'warn', 'useMaterial3: false', 'Saturn theme assumes M3', doc)

    def readme(self) -> None:
        a, doc = 'readme', 'readme-guide.md'
        if not self.exists('README.md'):
            self.add('readme.exists', a, 'fail', 'README.md missing', 'python3 tool/readme/init_readme.py', doc)
            return
        checker = self.root / 'tool/readme/check_readme.py'
        if checker.exists():
            # Before features exist only the structure is checked (--stage bootstrap).
            args = ['python3', str(checker)] + (['--stage', 'bootstrap'] if self.bootstrap else [])
            r = subprocess.run(args, cwd=self.root, capture_output=True, text=True)
            errors = [l for l in r.stdout.splitlines() if l.startswith('error')]
            warns = [l for l in r.stdout.splitlines() if l.startswith('warning')]
            # The release workflow runs the checker whenever it exists.
            self.add('readme.check', a, 'pass' if r.returncode == 0 else 'fail',
                     'check_readme.py ' + ('passes' + (f' ({len(warns)} warnings, e.g. {warns[0][9:80]})' if warns else '')
                                           if r.returncode == 0 else f'{len(errors)} errors: ' + errors[0][9:90]),
                     '' if r.returncode == 0 else 'python3 tool/readme/check_readme.py', doc, blocks=True)
        else:
            head = self.read('README.md')[:1500]
            has_head = '<img' in head and 'shields.io' in head
            self.add('readme.check', a, 'fail', 'README not on the template' + ('' if has_head else ' (no icon/badges/demo header)'),
                     'copy common/tool/readme/, init_readme.py, move dev notes under ## Development', doc)
        if not self.exists('README.ko.md'):
            self.add('readme.korean', a, 'warn' if self.exists('README.en.md') else 'fail',
                     'README.ko.md missing' + (' (has README.en.md — flip: README.md en, README.ko.md ko)' if self.exists('README.en.md') else ''),
                     'README.md English + README.ko.md Korean', doc)

    def meta(self) -> None:
        a = 'meta'
        claude = self.read('CLAUDE.md')
        m = re.search(r'conventions-v(\d+)', claude)
        if m:
            self.add('meta.claude-md', a, 'pass', f'CLAUDE.md records conventions-v{m.group(1)}')
        else:
            self.add('meta.claude-md', a, 'fail', 'CLAUDE.md does not record the applied conventions version',
                     'add the conventions line (conventions/README.md checklist step 10)', 'README.md')

    def release_readiness(self) -> None:
        a = 'release'
        status = self.git('status', '--porcelain')
        self.add('release.clean-tree', a, 'pass' if not status else 'fail',
                 'working tree clean' if not status else f'{len(status.splitlines())} uncommitted changes',
                 '' if not status else 'commit or stash')
        branch = self.git('rev-parse', '--abbrev-ref', 'HEAD')
        self.add('release.branch', a, 'pass' if branch == 'main' else 'warn', f'on branch {branch}',
                 '' if branch == 'main' else 'tags go on main after the bump PR merges', 'tagging.md')
        self.git('fetch', '--quiet', 'origin')
        behind = self.git('rev-list', '--count', 'HEAD..@{u}')
        ahead = self.git('rev-list', '--count', '@{u}..HEAD')
        if behind and behind != '0':
            self.add('release.up-to-date', a, 'fail', f'{behind} commits behind origin', 'git pull --ff-only', blocks=True)
        elif ahead and ahead != '0':
            # The tag goes on origin/main after the bump PR merges, so commits
            # that only exist locally would not be in the release.
            self.add('release.up-to-date', a, 'fail', f'{ahead} local commits not on origin — they would miss the release',
                     'git switch -c release/vX.Y.Z (keeps them), then git branch -f main origin/main; '
                     'bump on that branch and merge it by PR', 'tagging.md', blocks=True)
        else:
            self.add('release.up-to-date', a, 'pass', 'in sync with origin')
        v = self.pubspec_version().split('+')[0]
        tag = self.latest_tag()
        if tag and tag[1:] == v:
            self.add('release.version-bumped', a, 'fail', f'pubspec {v} is already released as {tag}',
                     'scripts/bump-version.sh patch|minor|major', 'versioning.md', blocks=True)
        elif v:
            self.add('release.version-bumped', a, 'pass', f'next release v{v} (latest {tag or "none"})')
            if self.git('tag', '--list', f'v{v}'):
                self.add('release.tag-free', a, 'fail', f'tag v{v} already exists (not the latest tag)',
                         'bump past it', 'tagging.md', blocks=True)
        self.secrets()

    def secrets(self) -> None:
        a = 'release'
        wf = self.root / '.github/workflows'
        used = set()
        for p in wf.glob('*.y*ml') if wf.is_dir() else []:
            used |= set(re.findall(r'secrets\.([A-Z0-9_]+)', p.read_text(encoding='utf-8', errors='replace')))
        used.discard('GITHUB_TOKEN')
        if not used:
            return
        url = self.git('remote', 'get-url', 'origin')
        m = re.search(r'github\.com[:/](.+?)(?:\.git)?$', url)
        try:
            out = subprocess.run(['gh', 'secret', 'list', '--json', 'name', '-R', m.group(1)] if m else ['false'],
                                 capture_output=True, text=True, check=True).stdout
            have = {s['name'] for s in json.loads(out)}
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError):
            self.add('release.secrets', a, 'warn', f'could not list repository secrets (needs gh auth); workflows use: '
                     + ', '.join(sorted(used)), 'check them in GitHub → Settings → Secrets', 'workflow.md')
            return
        missing = sorted(used - have)
        self.add('release.secrets', a, 'fail' if missing else 'pass',
                 f'missing secrets: {", ".join(missing)}' if missing else f'all {len(used)} workflow secrets set',
                 'register them (desktop/README.md, mobile/README.md)' if missing else '', 'workflow.md', blocks=True)

    def verdict(self) -> str:
        """go: nothing blocks · bump: only the version bump is missing · hold."""
        blocking = [c.id for c in self.checks if c.blocks_release]
        if not blocking:
            return 'go'
        return 'bump' if blocking == ['release.version-bumped'] else 'hold'

    def run(self) -> list[Check]:
        for step in (self.identity, self.versioning, self.workflow, self.packaging, self.about, self.icons,
                     self.licensing, self.fonts, self.localization, self.theming, self.ui, self.readme, self.meta):
            step()
        if self.release:
            self.release_readiness()
        return self.checks


ICON = {'pass': '✅', 'warn': '⚠️', 'fail': '❌', 'skip': '➖'}


def markdown(root: Path, checks: list[Check], platforms: list[str], verdict: str | None = None,
             stage: str = 'maintain') -> str:
    counts = {s: sum(c.status == s for c in checks) for s in ICON}
    blocking = [c for c in checks if c.blocks_release]
    upgrade = [c for c in checks if c.needed_for_upgrade]
    # 🛑 / ⤴ only mean something once an app releases; at bootstrap the goal is 0 ❌.
    detail = '' if stage == 'bootstrap' else f' (🛑 {len(blocking)} block a release, ⤴ {len(upgrade)} needed for the v1 workflow)'
    lines = [f'# Conventions audit: {root.name} — stage: {stage}', '',
             f'Platforms: {", ".join(platforms) or "none"} · '
             f'❌ {counts["fail"]}{detail} · ⚠️ {counts["warn"]} · ✅ {counts["pass"]}', '']
    if verdict:
        lines += [{'go': '**Release: ✅ go**', 'bump': '**Release: 🟡 bump the version, then go**',
                   'hold': '**Release: 🛑 hold**'}[verdict], '']
    area = None
    for c in sorted(checks, key=lambda c: (list(dict.fromkeys(x.area for x in checks)).index(c.area),
                                           {'fail': 0, 'warn': 1, 'pass': 2, 'skip': 3}[c.status])):
        if c.area != area:
            area = c.area
            lines += ['', f'## {area}', '', '| | check | result | fix |', '|---|---|---|---|']
        fix = c.fix + (f' ([doc]({c.doc}))' if c.doc and c.status in ('fail', 'warn') else '')
        mark = ICON[c.status] if stage == 'bootstrap' else \
            '🛑' if c.blocks_release else '⤴' if c.needed_for_upgrade else ICON[c.status]
        lines.append(f'| {mark} | `{c.id}` | {c.message} | {fix if c.status != "pass" else ""} |')
    return '\n'.join(lines) + '\n'


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('app', type=Path)
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--stage', choices=('bootstrap', 'release', 'maintain'), default='maintain')
    ap.add_argument('--release', action='store_true', help='same as --stage release')
    args = ap.parse_args()
    stage = 'release' if args.release else args.stage
    root = args.app.resolve()
    if not (root / 'pubspec.yaml').exists():
        raise SystemExit(f'{root}: no pubspec.yaml — pass the Flutter app directory')
    audit = Audit(root, stage)
    checks = audit.run()
    if args.json:
        print(json.dumps({'app': str(root), 'stage': stage, 'platforms': audit.platforms, 'modern_workflow': audit.modern,
                          'verdict': audit.verdict() if audit.release else None,
                          'checks': [asdict(c) for c in checks]}, ensure_ascii=False, indent=1))
    else:
        print(markdown(root, checks, audit.platforms, audit.verdict() if audit.release else None, stage))
    raise SystemExit(1 if any(c.status == 'fail' for c in checks) else 0)


if __name__ == '__main__':
    main()
