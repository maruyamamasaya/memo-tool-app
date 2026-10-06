---
status: active
updated: 2026-10-07
---

# 現在の状態

## 製品と実装

- Shared Memo V3 は Google ログインと Cloud Firestore を利用する単一ページの共有メモ Web アプリとして実装済み。
- メモの作成・1.5 秒後の自動保存・閲覧・論理削除/復元/完全削除、Markdown/テキスト表示、タグ、フォルダ、検索、作成/更新日時とタイトルによる並び替え、一括移動/削除/ダウンロードを備える。
- メモとフォルダは `group001` に固定され、Firestore snapshot listener でリアルタイム同期する。フィルタと並び替えは取得後にブラウザで行う。
- 5 テーマ、モバイル用ナビゲーション、デスクトップのサイドバー幅を端末に保存する。端末幅等に応じてメモ閲覧 UI が異なる。
- V1/V2 の欠損フィールドをクライアントで正規化し、通常保存時に現行フィールドを補う互換処理がある。

利用方法と画面単位の確認項目は [`README.md`](README.md)、構造とデータモデルは [`ARCHITECTURE.md`](ARCHITECTURE.md) を参照する。

- 一時/保存、固定、機密ラベル、プロンプト/コマンド/コード分類、本文そのまま入力とコピーを追加。既存データは保存/公開/メモとして扱う。

## 開発・運用状態

- ソースは `docs/shared-memo/` の HTML/CSS/JavaScript とルートの `firestore.rules`。package manager、コンパイル、バンドル工程はない。
- Nodeのモデル・認証連携テスト6件とFirestore EmulatorのRulesテスト4件を追加。検証方法は `TESTING.md` に集約した。
- GitHub Pages main/docsで公開済み。公開URLは `https://maruyamamasaya.github.io/memo-tool/shared-memo/`。
- shared-memo-63202のRulesをデプロイ済み。Mac常駐アプリのChrome認証と同期を確認。

## 既知の制約・未解決事項

1. 全 memos/folders を group 単位で購読しブラウザで検索・整列するため、件数増加時のページングや query 分割は未実装。
2. フォルダ削除は所属メモ更新とフォルダ削除を 1 batch に入れる。Firestore の batch 上限を超える規模では分割が必要。
3. CDN（Firebase SDK、marked、DOMPurify）と Firebase への接続が必須で、オフライン対応はない。
4. Windows実行、iOS共有拡張の認証付き実機検証は未完了。デスクトップZIPは未署名の試用版。
5. static verify の範囲外である認証・権限・レスポンシブ UI は Firebase 環境とブラウザでの手動確認を要する。

## 現在の優先事項

- 次の機能変更では、対象挙動の再現手順と最小限の自動検証を追加できるか検討する。
- 大量データ要件が現れた時点で、購読範囲、ページング、フォルダ削除 batch を見直す。要件がない段階で複雑化しない。
- Rules 変更時は Emulator/Rules Playground の検証方法と結果を session に残す。

## 次のアクション

新規タスクの要件に沿って決める。利用規模、障害報告、運用環境が不明なため、上記制約を推測で機能タスク化しない。
