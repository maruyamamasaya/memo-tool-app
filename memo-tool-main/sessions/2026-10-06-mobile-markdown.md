# Compact mobile Markdown

## Request
Use Shared Memo as a cross-platform clipboard for temporary notes and prompts, with smaller Markdown on iPhone; implement and deploy.

## Investigation
Existing Firestore synchronization and raw-body copy already support the workflow. GitHub Pages API confirms main /docs at https://maruyamamasaya.github.io/memo-tool/.

## Changes
At widths up to 700px, Markdown uses 14px body text, relative compact headings, tighter line and paragraph spacing. Both inline and popup viewers use matching styles. The editor stays unchanged. Made verification output compatible with macOS Bash 3.

## Validation
Full static verification and diff checks passed. Browser inspected a 390px document fixture and desktop document, with keyboard focus. Fixtures are local only. No signed-in account was available for cross-device Firebase testing. Companion iOS source passed Swift syntax parsing; no simulator tests or app distribution performed.

## Result
Prepared for deployment through existing main branch GitHub Pages publishing.

## Remaining Issues
Authenticated cross-device synchronization and real iPhone Safari verification require a signed-in device.
