# Cross-device workflow

## Request
Implement roadmap 1–6 while preserving the existing memo app, test each stage, and deploy. Include temporary/saved, confidential label, pinning, prompts/commands/code, iOS share extension, and Mac/Windows tray apps.

## Investigation
Existing Firebase project and GitHub Pages target confirmed. Existing CLI session expired and was refreshed by the user. Shared Keychain enables iOS extension authentication. Electron's embedded OAuth is replaced by a system-browser flow with an ephemeral origin/state-validated localhost callback.

## Changes
Optional metadata preserves legacy records as saved/public/note. Raw-body editor defaults preserve whitespace and trailing hash lines, and legacy editing remains selectable. Confidential bodies are excluded from search. Pinning and latest temporary sorting are supported. Mac arm64 and Windows x64 trial ZIPs were built. Companion iOS implementation and share extension are in memo-tool-app repository.

## Validation
6 Node tests pass. 4 Firestore Emulator tests pass (member/non-member, optional fields, old-client preservation, immutable fields, trash/restore). Browser fixture verified titleless command saving/copy, whitespace/hash preservation, confidential search exclusion, and mobile viewport. SwiftData legacy migration/trash/restore regression passes. iOS signed simulator build, archive and development IPA export succeed. Mac trial launches and shortcut restores its hidden window.

## Result
Firestore Rules deployed successfully. Web publication confirmed at commit 366065d. Chrome Google authentication successfully handed credentials to the Mac app; the native app shows signed-in and synchronized state. Reloading ignores cache, and versioned Web assets prevent the obsolete embedded popup flow.

## Remaining Issues
Windows runtime requires a Windows host. Desktop signing/notarization and App Store/TestFlight distribution are not configured. iOS Google sign-in and the share extension still require authenticated device verification. Mac Google sign-in is verified.
