# Search-first AI foundation session (2026-09-07)

## Request
AI が少ない context で対象コードへ到達し、安全に検証できる検索優先の開発基盤へ強化する。

## Investigation
既存 AI 文書、README、全 tracked path、主要 symbol、Firebase access、Rules、検証設定を確認した。CODEMAP/TESTING/OPERATIONS、CI、自動 test はなく、UI と DB access は単一 `app.js` に集中していた。

## Changes
役割別の 3 文書、検索優先の root guide、frontend 境界の子 AGENTS、依存不要の static/link verify を追加。CURRENT と README は正本への参照だけを更新し、製品コードや依存は変更していない。

## Validation
Fast/Full verify、`git diff --check` を実施。文書変更のみのため Firebase/browser 統合確認は対象外。

## Result
概念検索から exact/reference 検索へ絞る入口と、1 command の標準自動検証を用意した。

## Remaining Issues
unit/E2E/Rules Emulator と CI は未導入。`app.js` の責務集中は将来の機能変更時に必要性を再評価する。
