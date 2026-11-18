"""Query OSV for exact public package coordinates; sends no code or credentials.

Usage: python tool/audit_dependencies.py [--native build/audit/native-dependencies.txt]
"""
import argparse
import json
from pathlib import Path
import re
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', type=Path)
    parser.add_argument('--output', type=Path, default=Path('build/audit/dependency-advisories.json'))
    args = parser.parse_args()
    packages = set()
    lock = Path('pubspec.lock').read_text(encoding='utf-8')
    for match in re.finditer(r'^  (\w+):\n(.*?)(?=^  \w+:|^sdks:|\Z)', lock, re.M | re.S):
        version = re.search(r'^    version: "([^"]+)"', match[2], re.M)
        if version and 'source: sdk' not in match[2]:
            packages.add(('Pub', match[1], version[1]))
    if args.native:
        content = args.native.read_text(encoding='utf-8', errors='replace')
        for group, name, version, selected in re.findall(r'([\w.-]+):([\w.-]+):([\w.+-]+)(?: -> ([\w.+-]+))?', content):
            if group not in ('project', 'unspecified'):
                packages.add(('Maven', group + ':' + name, selected or version))
    packages = sorted(packages)
    queries = [dict(package=dict(ecosystem=eco, name=name), version=version) for eco, name, version in packages]
    findings = []
    for offset in range(0, len(queries), 100):
        batch = queries[offset:offset + 100]
        request = urllib.request.Request('https://api.osv.dev/v1/querybatch',
            data=json.dumps(dict(queries=batch)).encode(), headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(request, timeout=45) as response:
            results = json.load(response)['results']
        if len(results) != len(batch):
            raise ValueError('Incomplete OSV response')
        for query, result in zip(batch, results):
            if result.get('next_page_token'):
                raise ValueError('OSV pagination requires a follow-up query; do not report complete')
            if result.get('vulns'):
                findings.append(dict(**query, advisories=result['vulns']))
    report = dict(source='https://api.osv.dev/v1/querybatch', packages=packages, findings=findings)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2), encoding='utf-8')
    print('Exact package coordinates queried:', len(packages), 'packages with OSV advisories:', len(findings))
    for finding in findings:
        print(finding['package']['ecosystem'], finding['package']['name'], finding['version'],
              ','.join(v['id'] for v in finding['advisories']))


if __name__ == '__main__':
    main()
