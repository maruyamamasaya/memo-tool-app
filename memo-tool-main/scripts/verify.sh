#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-full}"
if [[ "$mode" != fast && "$mode" != full ]]; then echo "usage: $0 [fast|full]" >&2; exit 2; fi
python3 scripts/check_static.py
node --test tests/memo-options.test.mjs desktop/test/*.test.cjs
if [[ "$mode" == full ]]; then python3 scripts/check_markdown_links.py; fi
echo "${mode} validation passed. Browser/Firebase checks remain change-dependent; see TESTING.md."
