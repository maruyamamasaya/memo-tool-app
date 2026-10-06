# Knowledge bootstrap session (2026-08-28)

## 目的

次回以降の AI が最小限の情報から安全に開発を再開できるよう、既存資産を調査して共通フォーマットへ整理した。

## 調査範囲

- 全 tracked file とディレクトリ構成
- 現行 README、HTML/CSS/JavaScript、Firebase 設定、Firestore Rules
- AGENTS/CLAUDE、docs/documentation、`.github`、TODO/ROADMAP、package/pyproject、CI、test、migration/API/infra 設定の有無
- 全 commit 件名、直近履歴、主要機能 commit、初期 V1 README と Firebase 設定履歴
- 認証、membership、snapshot、localStorage、外部依存、batch、Markdown sanitize の実装箇所

既存 Markdown は README のみだった。AI 指示、現在状態、architecture、ADR、session と同等の別ファイルはなかった。DB migration/API 定義はなく、Firestore schema は README、クライアント、Rules に分散していた。

## 作成・統合

- `AGENTS.md`: 調査順、変更原則、実在する検証手段、Definition of Done。
- `CURRENT.md`: 実装済み機能、開発/運用状態、既知の制約、優先事項。
- `ARCHITECTURE.md`: 静的クライアント、Firebase、認可、データモデル、データフロー、配信と外部依存。
- `decisions/ADR-001-static-firebase-client-and-group-authorization.md`: 履歴とコードで確認できた静的 Firebase 構成と group authorization。元の比較検討は不明と明記。
- README は独立した利用・導入・手動確認資料として維持し、現行実装と異なった localStorage/クライアント処理の記述だけを修正した。

## 削除・廃止候補

削除した文書はなく、現時点の廃止候補もない。README の詳細手順は新しい 5 分類に複製せず、参照資料として残す価値がある。

## 不明・確認不能

- GitHub Pages の設定、公開 URL、現在稼働している revision。
- Firebase Console の Authentication/Authorized domains/group members と、実際に deploy された Rules。
- 当初の候補比較、運用責任者、想定最大データ量。
- 実ブラウザ/Firebase 環境での現行版の回帰テスト結果。

## 今後確認すること

具体的なタスクや障害時に関連する不明点だけを確認する。Rules 変更時は Emulator/Rules Playground の結果を残し、大量データ要件が現れた場合は購読と batch 上限を再設計する。

## 自己レビュー

次回の AI は `AGENTS.md` → `CURRENT.md` → `ARCHITECTURE.md` → 関連 ADR → 対象コードの順で、製品状態、責務、セキュリティ境界、検証制約を把握できる。利用/導入詳細は README、今回の根拠と確認不能事項はこの session へ分離した。リポジトリから確定できる継続開発情報に重大な欠落は見つからない。外部環境は推測せず確認不能として引き継いだ。
