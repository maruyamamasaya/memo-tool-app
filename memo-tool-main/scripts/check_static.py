#!/usr/bin/env python3
"""Dependency-free consistency checks for the static application."""
import re, subprocess, sys, tempfile
from html.parser import HTMLParser
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; APP=ROOT/'docs/shared-memo'
class Parser(HTMLParser):
    def __init__(self): super().__init__(); self.ids=set(); self.assets=[]
    def handle_starttag(self,tag,attrs):
        values=dict(attrs)
        if values.get('id'): self.ids.add(values['id'])
        key='href' if tag=='link' else 'src' if tag=='script' else None
        if key and values.get(key,'').startswith('./'): self.assets.append(values[key].split("?",1)[0])
def main():
    parser=Parser(); parser.feed((APP/'index.html').read_text())
    errors=[f'missing local asset: {a}' for a in parser.assets if not (APP/a).is_file()]
    app=(APP/'app.js').read_text(); match=re.search(r'const ids = \[(.*?)\];',app,re.S)
    if not match: errors.append('app.js: ids registry not found')
    else:
        registered=set(re.findall(r'"([^"]+)"',match.group(1)))
        errors += [f'app.js id absent from index.html: {i}' for i in sorted(registered-parser.ids)]
    for path in (APP/'app.js',APP/'firebase-config.js',APP/'memo-options.mjs'):
        source=re.sub(r'^import .*?;\s*$','',path.read_text(),flags=re.M)
        source=re.sub(r'^export\s+','',source,flags=re.M)
        with tempfile.NamedTemporaryFile('w',suffix='.js') as copy:
            copy.write(source); copy.flush()
            result=subprocess.run(['node','--check',copy.name],capture_output=True,text=True)
        if result.returncode: errors.append(f'{path.relative_to(ROOT)}: {result.stderr.strip()}')
    if errors: print('\n'.join('ERROR: '+e for e in errors),file=sys.stderr); return 1
    print('Static assets, DOM IDs, and JavaScript syntax: OK'); return 0
if __name__=='__main__': raise SystemExit(main())
