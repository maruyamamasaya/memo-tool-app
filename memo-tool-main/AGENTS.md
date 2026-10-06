# AI 継続開発ガイド

このファイルは全体共通の作業ルールだけを扱う。対象ディレクトリに近い `AGENTS.md` があれば、その追加ルールにも従う。

## 検索優先の探索

1. このファイルと [`CURRENT.md`](CURRENT.md) で制約と現在地を確認する。
2. [`CODEMAP.md`](CODEMAP.md) から入口と検索語を選び、必要な節だけ [`ARCHITECTURE.md`](ARCHITECTURE.md) で確認する。
3. symbol 名が不明なら、利用可能な semantic/repository search を先に使う。分かった後は symbol/reference search、なければ `rg` / `git grep` で definition、references、tests、configuration、data dependencies を絞る。
4. 対象コードとその呼び出し元・呼び出し先だけを読み、最も近い `AGENTS.md` を確認する。

README、全 session、全 ADR、全コードを最初から順番に読まない。semantic search がない環境では CODEMAP の語を `rg` で組み合わせる。コードと文書の矛盾は実装と履歴を調査し、意図は推測しない。

## 変更ルール

- 無関係な整形、依存更新、大規模 rename/refactor を混ぜず、変更を最小化する。
- Vanilla JavaScript の静的アプリ構成を維持し、新規ツールや依存は必要性を説明できる場合だけ追加する。
- Firebase Authentication と Firestore Rules を権限境界とし、クライアント判定だけに依存しない。
- 管理用秘密鍵やサービスアカウントを commit しない。Firebase Web 設定は公開識別子であり Rules で保護する。
- CDN は browser ESM、バージョン固定、Markdown の DOMPurify sanitize を維持する。
- エラーを隠す回避策を恒久化しない。未解決なら `CURRENT.md` または session に残す。

## 検証と完了条件

検証の正本は [`TESTING.md`](TESTING.md)。実装中は `./scripts/verify.sh fast`、完了前は `./scripts/verify.sh` を実行し、変更種別に応じた手動/Firebase 検証も行う。最後に `git diff --check` と `git diff` を確認する。

## ドキュメントの正本と更新条件

| 文書 | 役割 / 更新する条件 |
| --- | --- |
| `CURRENT.md` | 現在地。状態・優先事項・既知問題が変わった時 |
| `ARCHITECTURE.md` | 現行構造とデータフロー。構造や境界が変わった時 |
| `CODEMAP.md` | 検索入口。主要入口・配置・検索語が変わった時 |
| `TESTING.md` | 検証の正本。方法や必要条件が変わった時 |
| `OPERATIONS.md` | 起動・設定・deploy。運用方法が変わった時 |
| `decisions/` | 将来も理由が必要な重要判断が生じた時 |
| `sessions/` | AI 作業終了時 |
| `README.md` | 人間向けの概要と利用方法が変わった時 |

詳細は正本へリンクし、別文書へコピーしない。session は Request / Investigation / Changes / Validation / Result / Remaining Issues の短い要約とし、生ログ、巨大な diff、思考過程を残さない。
