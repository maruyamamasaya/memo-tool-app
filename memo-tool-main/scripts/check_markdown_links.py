#!/usr/bin/env python3
"""Check local relative links in tracked Markdown files."""
import re, subprocess
from pathlib import Path
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[1]; LINK=re.compile(r'(?<!!)\[[^]]*\]\(([^)]+)\)')
def main():
    names=subprocess.check_output(['git','ls-files','*.md'],cwd=ROOT,text=True).splitlines()
    # Include newly created Markdown before its first commit.
    names=sorted(set(names)|{str(p.relative_to(ROOT)) for p in ROOT.rglob('*.md') if '.git' not in p.parts and 'node_modules' not in p.parts and 'dist' not in p.parts})
    errors=[]
    for name in names:
        path=ROOT/name
        for number,line in enumerate(path.read_text().splitlines(),1):
            for raw in LINK.findall(line):
                target=raw.split('#',1)[0]
                if target and '://' not in target and not target.startswith('mailto:') and not (path.parent/unquote(target)).resolve().exists():
                    errors.append(f'{name}:{number}: missing link target {target}')
    if errors: print('\n'.join(errors)); return 1
    print('Markdown relative links: OK'); return 0
if __name__=='__main__': raise SystemExit(main())
