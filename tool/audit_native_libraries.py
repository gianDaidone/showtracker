"""Inspect actual packaged ELF LOAD alignment (no device installation).

Usage: python tool/audit_native_libraries.py path/to/app.apk [--output report.json]
ZIP alignment is checked for uncompressed APK libraries. Runtime compatibility
must also be checked on an isolated device.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zipfile


def inspect_elf(data):
    if data[:4] != b'\x7fELF' or data[5] != 1:
        raise ValueError('Unsupported ELF header')
    is64 = data[4] == 2
    if is64:
        offset = struct.unpack_from('<Q', data, 32)[0]
        size, count = struct.unpack_from('<HH', data, 54)
    else:
        offset = struct.unpack_from('<I', data, 28)[0]
        size, count = struct.unpack_from('<HH', data, 42)
    loads = []
    relro = []
    for index in range(count):
        record = offset + index * size
        if is64:
            kind, flags, file_offset, address, _, file_size, memory_size, alignment = struct.unpack_from('<IIQQQQQQ', data, record)
        else:
            kind, file_offset, address, _, file_size, memory_size, flags, alignment = struct.unpack_from('<IIIIIIII', data, record)
        segment = dict(offset=file_offset, address=address, file_size=file_size,
                       memory_size=memory_size, flags=flags, alignment=alignment)
        if kind == 1:
            loads.append(segment)
        if kind == 0x6474e552:
            relro.append(segment)
    compatible = bool(loads) and all(s['alignment'] >= 16384 and
        (s['address'] - s['offset']) % 16384 == 0 for s in loads)
    # Check the Android-documented RELRO boundary hazard only when writable
    # data follows RELRO in that same LOAD segment.
    hazard = any((r['address'] + r['memory_size']) % 16384 and
        any(s['flags'] & 2 and s['address'] <= r['address'] and
            s['address'] + s['memory_size'] > r['address'] + r['memory_size']
            for s in loads) for r in relro)
    return dict(bits=64 if is64 else 32, load_alignments=[s['alignment'] for s in loads],
                compatible_16kb=compatible, relro_boundary_hazard=hazard)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.artifact.suffix != '.apk':
        parser.error('Expected an APK file')
    results = []
    with zipfile.ZipFile(args.artifact) as archive:
        for entry in archive.infolist():
            if not entry.filename.endswith('.so'):
                continue
            data = archive.read(entry)
            result = dict(path=entry.filename, sha256=hashlib.sha256(data).hexdigest(), **inspect_elf(data))
            if args.artifact.suffix == '.apk' and entry.compress_type == zipfile.ZIP_STORED:
                with args.artifact.open('rb') as source:
                    source.seek(entry.header_offset + 26)
                    name_length, extra_length = struct.unpack('<HH', source.read(4))
                result['zip_aligned_16kb'] = (entry.header_offset + 30 + name_length + extra_length) % 16384 == 0
            results.append(result)
    report = dict(artifact=str(args.artifact), sha256=hashlib.sha256(args.artifact.read_bytes()).hexdigest(), libraries=results)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2), encoding='utf-8')
    for result in results:
        print(result['path'], 'LOAD:', result['load_alignments'],
              '16KB:', result['compatible_16kb'], 'RELRO hazard:', result['relro_boundary_hazard'])
    required = [r for r in results if r['bits'] == 64]
    if not required or any(not r['compatible_16kb'] or r['relro_boundary_hazard'] or
                           not r.get('zip_aligned_16kb', True) for r in required):
        raise SystemExit('FAIL: packaged 64-bit native alignment requires attention')
    print('PASS: packaged 64-bit native alignment; runtime testing still required')


if __name__ == '__main__':
    main()
