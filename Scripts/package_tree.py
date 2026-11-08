#!/usr/bin/env python3
#
#  package_tree.py
#  ai-chatbot
#
#  Created by Wendra on 08/11/26.
#

"""Generate or check the complete, versioned DesignKit and TanyaAI file tree."""
import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'docs/PACKAGE_TREE.md'
PACKAGES = ('Packages/DesignKit', 'Packages/TanyaAI')


def package_paths():
    result = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', *PACKAGES], cwd=ROOT
    )
    return sorted({path for path in result.decode().split('\0') if path and (ROOT / path).is_file()})


def tree_lines(node, prefix=''):
    names = sorted(node, key=lambda name: (not bool(node[name]), name.casefold(), name))
    for index, name in enumerate(names):
        is_last = index == len(names) - 1
        branch = '└── ' if is_last else '├── '
        suffix = '/' if node[name] else ''
        yield prefix + branch + name + suffix
        child_prefix = prefix + ('    ' if is_last else '│   ')
        yield from tree_lines(node[name], child_prefix)


def render(paths):
    tree = {}
    for path in paths:
        node = tree
        for part in Path(path).parts[1:]:
            node = node.setdefault(part, {})
    counts = [f'- **{name.split("/")[-1]}:** {sum(path.startswith(name + "/") for path in paths)} file.'
              for name in PACKAGES]
    return '\n'.join([
        '# Tree lengkap DesignKit dan TanyaAI', '',
        'Dihasilkan oleh `python3 Scripts/package_tree.py`. Aturan penempatan ada di',
        '[PACKAGE_STRUCTURE.md](PACKAGE_STRUCTURE.md). Tree ini mencantumkan seluruh file package',
        'yang dikelola Git, termasuk source, tests, token, font/lisensi, isi xcassets, localization,',
        'manifest, dan shared scheme Xcode. File lokal baru yang tidak di-ignore juga ikut dicatat.',
        'Build output, cache, serta konfigurasi pribadi yang di-ignore tidak termasuk.', '',
        *counts, f'- **Total:** {len(paths)} file.', '',
        '```text', 'Packages/', *tree_lines(tree), '```', '',
        'Tidak ada folder intent kosong. Folder intent ditambahkan bersama implementasi flow pertamanya.', '',
        'Setelah menambah atau memindahkan file, jalankan generator ini. Pemeriksaan',
        '`python3 Scripts/package_tree.py --check` juga dijalankan oleh `Scripts/check_style.sh`.', ''
    ])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Fail if the documented tree differs from the files.')
    args = parser.parse_args()
    paths = package_paths()
    expected = render(paths)
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text() != expected:
            parser.exit(1, 'Package tree is out of date. Run: python3 Scripts/package_tree.py\n')
        print(f'Package tree matches all {len(paths)} files.')
        return
    OUTPUT.write_text(expected)
    print(f'Generated {OUTPUT.relative_to(ROOT)} with all {len(paths)} files.')


if __name__ == '__main__':
    main()
