# Testing

検証方法の正本。package manager、build、lint、typecheck、unit/E2E test framework はない。標準入口は依存追加なしの `./scripts/verify.sh` であり、ブラウザ/Firebase 統合確認の代替ではない。

## Fast validation（実装中）
```sh
./scripts/verify.sh fast
```
ローカル asset/DOM ID の整合性と、CDN import/export を除いた JavaScript コピーの構文を確認する。

## Full validation（完了前）
```sh
./scripts/verify.sh
git diff --check
```
現時点の自動化可能な全 check を実行する。Fast と同じ check に加え、tracked な Markdown の内部相対 link を確認する。さらに下表で必要な手動確認を行う。Firebase 資格情報やブラウザを必要とする項目を実施できない場合は、session と最終報告に明記する。

## Change type → required validation
| Change type | Required validation |
| --- | --- |
| 文書のみ | Full validation、link と記述の対象コードを spot check |
| HTML/CSS/UI | Fast、静的配信、対象 viewport と keyboard 操作のブラウザ確認 |
| `app.js` の共有ロジック | Fast、対象操作、完了前に Full |
| 認証・Firestore access | Full、ログイン/ログアウト、member/non-member、別 group、同期を実 Firebase か Emulator で確認 |
| `firestore.rules` | Full、Emulator または Rules Playground で member/non-member と create/update/delete を確認 |
| config/CDN | Full、静的配信、network/console、browser ESM、version pin、Markdown sanitize を確認 |
| architecture/全体変更 | Full、主要操作一式、該当ドキュメント更新 |

## Manual browser and integration checks

静的配信の起動は [`OPERATIONS.md`](OPERATIONS.md) を参照する。対象変更に絞って次を確認する。

- browser console と network に予期しない error がなく、画面 asset が取得できる。
- 認証、固定 group membership、メモ/フォルダ CRUD、snapshot の別 browser 同期。
- 検索・sort・tag・folder・trash・bulk 操作と旧 document の正規化。
- Markdown が sanitize され、text は HTML として解釈されない。
- UI 変更では 700px 以下/超、keyboard、dialog、theme/localStorage。

本番 Firebase の詳細な利用シナリオは人間向け [`README.md`](README.md#動作確認) にある。

## 共有クリップボードの回帰

標準verifyに旧データ既定値・用途/機密/固定のフィルター・生本文保持・常駐アプリ認証コールバックのテストを含む。コールバックテストはlocalhostのbindが必要。

FirestoreはFirebase CLI、Java 21以上、`@firebase/rules-unit-testing`と`firebase`を利用して、`firebase emulators:exec --only firestore --project demo-shared-memo 'node --test tests/firestore-rules.test.mjs'`で確認する。テスト依存はtestsから解決可能な位置に準備する。本番プロジェクトでこのテストを実行しない。

画面では一時→保存への変更、旧メモ保持、タイトル不要の保存、機密本文検索除外、字下げ・末尾#を含む本文コピー、エディター失敗時に閉じないことを確認する。デスクトップはGoogleログインのシステムブラウザ引継ぎ・トレイ・ショートカット・終了を確認する。
