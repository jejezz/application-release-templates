#!/usr/bin/env python3
"""Write README.md and README.ko.md from the templates (conventions/readme-guide.md).

    python3 tool/readme/init_readme.py            # refuses to overwrite
    python3 tool/readme/init_readme.py --force    # replace existing READMEs

Fills in everything the repository already knows:

  {{DISPLAY_NAME}}    lib/app_identity.dart displayName, else AppInfo.xcconfig PRODUCT_NAME
  {{FILE_NAME}}       display name without spaces (conventions/identity.md §2)
  {{REPO_SLUG}}       owner/repo from `git remote get-url origin`
  {{PLATFORM_*}}      from the platform folders that exist
  {{MIN_MACOS}}       macos/Podfile `platform :osx`, else the Xcode project's MACOSX_DEPLOYMENT_TARGET
  {{RUN_DEVICE}}      macos / windows / linux / a phone
  {{YEAR}}            AppIdentity.firstReleaseYear, else this year

and keeps only the <!-- if:… --> blocks for those platforms. What only you
know is left as {{TODO: …}} — tool/readme/check_readme.py fails until each
is filled in.

From jejezz/application-release-templates common/ @ conventions-v1.
"""
from __future__ import annotations

import datetime
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
TARGETS = {'README.template.md': 'README.md', 'README.ko.template.md': 'README.ko.md'}


def read(path: str) -> str:
    p = ROOT / path
    return p.read_text(encoding='utf-8') if p.exists() else ''


def display_name() -> str:
    m = re.search(r"displayName\s*=\s*'([^']+)'", read('lib/app_identity.dart'))
    if m and not m.group(1).startswith('__'):
        return m.group(1)
    m = re.search(r'^PRODUCT_NAME\s*=\s*(.+)$', read('macos/Runner/Configs/AppInfo.xcconfig'), re.M)
    if m:
        return m.group(1).strip()
    raise SystemExit('display name not found: fill lib/app_identity.dart or AppInfo.xcconfig PRODUCT_NAME first')


def repo_slug() -> str:
    try:
        url = subprocess.run(['git', 'remote', 'get-url', 'origin'], cwd=ROOT,
                             capture_output=True, text=True, check=True).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return '{{TODO: owner/repo}}'
    m = re.search(r'github\.com[:/](.+?)(?:\.git)?$', url)
    return m.group(1) if m else '{{TODO: owner/repo}}'


def platforms() -> list[str]:
    return [p for p in ('macos', 'windows', 'linux', 'ios', 'android') if (ROOT / p).is_dir()]


def min_macos() -> str:
    # The Podfile only exists once a plugin needed CocoaPods; the Xcode
    # project always has the deployment target.
    m = (re.search(r"platform\s+:osx,\s*'([\d.]+)'", read('macos/Podfile'))
         or re.search(r'MACOSX_DEPLOYMENT_TARGET = ([\d.]+);', read('macos/Runner.xcodeproj/project.pbxproj')))
    return m.group(1) if m else '{{TODO: minimum macOS}}'


def first_year() -> str:
    m = re.search(r'firstReleaseYear\s*=\s*(\d{4})', read('lib/app_identity.dart'))
    return m.group(1) if m else str(datetime.date.today().year)


def keep_blocks(text: str, enabled: set[str]) -> str:
    """Resolve <!-- if:x --> … <!-- endif:x --> (nested, one per line)."""
    out, stack = [], []
    for line in text.splitlines(keepends=True):
        opening = re.fullmatch(r'\s*<!-- if:(\w+) -->\s*', line)
        closing = re.fullmatch(r'\s*<!-- endif(?::\w+)? -->\s*', line)
        if opening:
            stack.append(opening.group(1) in enabled)
        elif closing:
            stack.pop()
        elif all(stack):
            out.append(line)
    return re.sub(r'\n{3,}', '\n\n', ''.join(out))


def main() -> None:
    force = '--force' in sys.argv[1:]
    plats = platforms()
    if not plats:
        raise SystemExit('no platform folders found — run from a Flutter app')
    desktop = [p for p in plats if p in ('macos', 'windows', 'linux')]
    mobile = [p for p in plats if p in ('ios', 'android')]
    enabled = set(plats) | ({'desktop'} if desktop else set()) | ({'mobile'} if mobile else set())

    names = {'macos': 'macOS', 'windows': 'Windows', 'linux': 'Linux', 'ios': 'iOS', 'android': 'Android'}
    name = display_name()
    values = {
        'DISPLAY_NAME': name,
        'FILE_NAME': re.sub(r'[^0-9A-Za-z]', '', name),
        'REPO_SLUG': repo_slug(),
        'PLATFORM_TEXT': ' · '.join(names[p] for p in plats),
        # shields.io: `-` separates fields, so spaces become %20 and the
        # separator is a URL-encoded middle dot.
        'PLATFORM_BADGE': '%20%C2%B7%20'.join(names[p] for p in plats),
        'MIN_MACOS': min_macos() if 'macos' in plats else '',
        'RUN_DEVICE': desktop[0] if desktop else '<device-id>',
        'YEAR': first_year(),
    }

    for template, target in TARGETS.items():
        out = ROOT / target
        if out.exists() and not force:
            print(f'skip     {target} (exists — use --force to replace)')
            continue
        text = keep_blocks((HERE / template).read_text(encoding='utf-8'), enabled)
        for key, value in values.items():
            text = text.replace('{{' + key + '}}', value)
        out.write_text(text, encoding='utf-8')
        todos = len(re.findall(r'\{\{TODO', text))
        print(f'wrote    {target} ({todos} TODOs to fill)')


if __name__ == '__main__':
    main()
