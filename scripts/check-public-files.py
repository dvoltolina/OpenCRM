#!/usr/bin/env python3
"""Reject private artifacts and recognizable credentials without printing values."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {
    '.git', 'node_modules', '.dart_tool', '.venv', 'venv', 'build', 'dist',
    '__pycache__', '.pytest_cache', '.next', '.gradle', 'Pods', '.cache',
}
PATTERNS = {
    'private key': re.compile(r'-----BEGIN (?:[A-Z ]+)?PRIVATE KEY-----'),
    'Google API key': re.compile(r'AIza[0-9A-Za-z_-]{30,}'),
    'GitHub credential': re.compile(r'(?:gh[pousr]_[A-Za-z0-9_]{30,}|github_pat_[A-Za-z0-9_]{30,})'),
    'AWS access key': re.compile(r'(?:AKIA|ASIA)[A-Z0-9]{16}'),
    'Stripe credential': re.compile(r'(?:sk|rk|pk)_(?:live|test)_[A-Za-z0-9]{20,}'),
    'Slack credential': re.compile(r'xox[baprs]-[A-Za-z0-9-]{20,}'),
    'provider credential': re.compile(r'(?:sk-(?:proj-)?[A-Za-z0-9_-]{30,}|SG\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{20,})'),
    'OAuth client registration': re.compile(r'\d{10,}-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com'),
    'Firebase app registration': re.compile(r'\b1:\d{8,}:(?:web|ios|android):[A-Fa-f0-9]+'),
    'analytics registration': re.compile(r'\b(?:G-[A-Z0-9]{8,}|GTM-[A-Z0-9]{5,}|UA-\d+-\d+)\b'),
    'personal filesystem path': re.compile(r'(?<![\w./])/(?:Users|home)/[A-Za-z0-9._-]+'),
    'Apple signing team': re.compile(r'DEVELOPMENT_TEAM\s*=\s*"?[A-Z0-9]{10}"?\s*;'),
}


def candidates():
    if (ROOT / '.git').exists():
        result = subprocess.run(
            ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
            cwd=ROOT, check=True, stdout=subprocess.PIPE,
        )
        return [ROOT / p.decode() for p in result.stdout.split(b'\0') if p]
    import os
    found = []
    for current, dirs, files in os.walk(ROOT, followlinks=False):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        found.extend(Path(current) / f for f in files)
    return found


failures = []
checked = 0
for path in sorted(set(candidates())):
    rel = path.relative_to(ROOT)
    if any(p in SKIP_DIRS for p in rel.parts):
        # Cached build/dependency files must not be published, even if ignored.
        if (ROOT / '.git').exists():
            tracked = subprocess.run(['git', 'ls-files', '--error-unmatch', str(rel)], cwd=ROOT,
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
            if tracked:
                failures.append(f'{rel}: tracked dependency or build artifact')
        continue
    if path.is_symlink():
        failures.append(f'{rel}: symbolic links require explicit publication review')
        continue
    name = path.name
    local_env = name.startswith('.env') and not name.endswith(('.example', '.sample'))
    forbidden = name in {'.firebaserc', 'google-services.json', 'GoogleService-Info.plist',
                        'firebase-config.js', 'firebase_options.local.dart', '.DS_Store', 'key.properties'}
    sensitive_file = bool(re.search(r'(?:service[-_]?account|firebase-adminsdk|credentials).*\.json$', name, re.I))
    private_dir = any(p in {'.aws', '.config', '.claude', '.codex', '.firebase', '.vercel', '.idea', '.vscode'} for p in rel.parts)
    if local_env or forbidden or sensitive_file or private_dir or path.suffix.lower() in {
        '.pem', '.key', '.p12', '.pfx', '.jks', '.keystore', '.mobileprovision', '.log', '.bak', '.bak2', '.ipynb',
    }:
        failures.append(f'{rel}: private or generated artifact')
    if not path.is_file():
        continue
    checked += 1
    try:
        content = path.read_text(encoding='utf-8')
    except UnicodeError:
        continue
    for label, pattern in PATTERNS.items():
        for match in pattern.finditer(content):
            line = content.count('\n', 0, match.start()) + 1
            failures.append(f'{rel}:{line}: {label}')

if failures:
    print('\n'.join(failures))
    print(f'Public source check failed: {len(failures)} findings in {checked} files.')
    sys.exit(1)
print(f'Public source check passed: {checked} files; no recognized credentials or private artifacts.')
