"""Heuristic scan of tracked content and all reachable Git history.

Only rule, path, line and first commit are emitted. Never prints matched values.
Does not read ignored/local credential files. Findings require owner rotation;
absence of matches is not proof that no credential exists.
"""
import re
import subprocess

RULES = {
    'credential-literal': r'''(?i)(?:api_?key|tmdb_?key|rawg_?key|session_?id|secret|token)["']?\s*[:=]\s*["'][A-Za-z0-9_\-]{24,}["']''',
    'provider-token': r'gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AIza[A-Za-z0-9_\-]{30,}|AKIA[A-Z0-9]{16}',
    'private-key': r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
}


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, check=True).stdout


def main():
    revisions = git('rev-list', '--all').decode().splitlines()
    seen = set()
    findings = set()
    blobs = 0
    for revision in revisions:
        for line in git('ls-tree', '-r', revision).decode('utf-8', errors='replace').splitlines():
            metadata, path = line.split('\t', 1)
            mode, kind, digest = metadata.split()
            if kind != 'blob' or digest in seen:
                continue
            seen.add(digest)
            # Avoid large lockfile/binary hashes being mistaken for secrets.
            data = git('cat-file', 'blob', digest)
            if b'\x00' in data or len(data) > 2 * 1024 * 1024:
                continue
            blobs += 1
            for number, content in enumerate(data.decode('utf-8', errors='replace').splitlines(), 1):
                for rule, pattern in RULES.items():
                    if re.search(pattern, content):
                        findings.add((rule, path, number, revision[:12]))
    # Include current tracked edits, without accessing untracked credential files.
    for path in git('ls-files', '-z').decode().split('\0'):
        if not path:
            continue
        from pathlib import Path
        file = Path(path)
        if not file.is_file() or file.stat().st_size > 2 * 1024 * 1024:
            continue
        data = file.read_bytes()
        if b'\x00' in data:
            continue
        for number, content in enumerate(data.decode('utf-8', errors='replace').splitlines(), 1):
            for rule, pattern in RULES.items():
                if re.search(pattern, content):
                    findings.add((rule, path, number, 'working-tree'))
    print('Reachable commits:', len(revisions), 'unique text blobs:', blobs)
    print('Heuristic findings:', len(findings))
    for finding in sorted(findings):
        print(*finding, sep=' | ')


if __name__ == '__main__':
    main()
