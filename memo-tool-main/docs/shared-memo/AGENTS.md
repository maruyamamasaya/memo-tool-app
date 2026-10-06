# Shared Memo frontend rules

この directory は browser で直接配信する Vanilla JavaScript frontend。root `AGENTS.md` に加えて従う。

- `index.html` の ID を変える時は `app.js` の `ids`、event binding、CSS selector を references search する。
- Firebase 読み書きを変える時は collection、payload、legacy normalization、`firestore.rules` を一緒に確認する。
- 認証前の member 判定は UX であり、認可を client code だけに追加しない。
- CDN import は browser ESM と固定 version を保つ。Markdown HTML は必ず DOMPurify を経由させる。
- `sharedMemoV3.*` key、700px breakpoint、旧 document defaults の互換性を変更する場合は移行影響を記録する。
- 実装中は `./scripts/verify.sh fast`。UI 変更は static server で該当 viewport と keyboard 操作も確認する。

入口と検索語は [`../../CODEMAP.md`](../../CODEMAP.md)、検証詳細は [`../../TESTING.md`](../../TESTING.md) を参照し、ここへ複製しない。
