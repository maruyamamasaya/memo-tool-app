---
status: active
updated: 2026-10-07
---

# アーキテクチャ

## 全体像

```text
Browser (GitHub Pages/static server)
  index.html + style.css + app.js
    ├─ Google Authentication ─ Firebase Authentication
    ├─ snapshot/read/write ──── Cloud Firestore
    ├─ Markdown parse ───────── marked (CDN)
    └─ HTML sanitize ────────── DOMPurify (CDN)
Firestore requests ──────────── firestore.rules
```

独自 server/API はない。ブラウザが Firebase Web SDK を CDN から ESM として読み込み、Firestore を直接操作する。相対パスを使うため GitHub Pages の `/docs` とローカル HTTP server で配信できる。この構成と権限境界は [`ADR-001`](decisions/ADR-001-static-firebase-client-and-group-authorization.md) に記録する。

Mac/WindowsのElectron常駐アプリは同じWebをsandbox付きで表示する。Google認証はシステムブラウザで行い、短命のlocalhostコールバックでoriginとnonceを検証して認証情報を渡す。Firestoreの認可境界は共通。

## コンポーネント責務

| パス | 責務 |
| --- | --- |
| `docs/shared-memo/index.html` | 画面構造、dialog、アクセシビリティ属性、entry point |
| `docs/shared-memo/style.css` | テーマ、レスポンシブ表示、画面/部品のスタイル |
| `docs/shared-memo/app.js` | UI 状態、認証、正規化、購読/更新、検索/整列、Markdown 表示 |
| `docs/shared-memo/firebase-config.js` | Firebase Web アプリ識別情報と既定 `group001` |
| `firestore.rules` | Firestore 認可、入力形状、監査フィールド不変条件 |
| `README.md` | 利用者/運用者向け設定、仕様概要、手動確認 |

`app.js` は画面状態と Firebase 処理を同じファイルで扱う。これは現在状態であり、将来も単一ファイルにすべきという判断は確認できない。

## 認証・認可フロー

1. Firebase 初期化後、Google popup でログインする。
2. auth state 受信後、本人の `users/{uid}` へ表示名とメールを merge する。
3. クライアントが `groups/group001` を読み、`members` に UID があるか確認する。
4. メンバーなら memos/folders を `groupId == group001` で購読する。
5. すべての request を別途 `firestore.rules` が認可する。手順 3 は UX 上の事前確認で、セキュリティ境界は Rules である。

グループはクライアントから変更できず、信頼された管理経路が必要。具体的な運用担当・手順は不明。

## データモデル

### `groups/{groupId}`

少なくとも `members: string[]` を持つ。クライアントは `group001` のみ使用し、Rules は group 書き込みを拒否する。

### `users/{uid}`

`displayName`, `email` をログイン時に merge する。本人だけが read/create/update でき、delete は拒否される。

### `memos/{memoId}`

- 所属: `groupId`, `folderId`
- 内容: `title`, `body`, `type`, `format`, `tags`, `pinned`
- 任意分類: `usage` (temporary/saved), `confidential` (boolean), `contentKind` (note/prompt/command/code)。旧データの既定値はsaved/false/note。
- 状態: `trashed`, `trashedAt`, `lastOpenedAt`
- 監査: `createdBy`, `createdByName`, `createdAt`, `updatedBy`, `updatedByName`, `updatedAt`

Rules は title、type/format、タグ数、UID、server timestamp、作成監査フィールドの不変性を検査する。`type` と `pinned` は互換データとして残るが、現行 UI は単一エディタと format/folder/tag 操作が中心。旧 document はクライアントで既定値へ正規化し、Rules も更新時に段階的移行を許容する。

### `folders/{folderId}`

`groupId`, `name`, `color`, `createdBy`, `createdAt` を持つ。名前と色だけ更新可能。削除時は所属メモを未分類 (`folderId: null`) にし、同じ batch で folder を削除する。

## 主要データフロー

- **同期:** memos/folders を group 条件 1 つで `onSnapshot` 購読し、ブラウザ内配列へ格納。
- **表示:** view/folder/tag/search/date/sort によりブラウザ内で絞り込み・整列。複合 index は前提にしない。
- **編集:** textarea の 1 行目を title、最終行の `#タグ` 群を tags、その間を body とし、入力停止 1.5 秒後に保存。
- **Markdown:** `.md` は marked で HTML 化後、DOMPurify で sanitize。`.txt` は text として表示。
- **削除:** 通常は `trashed` による論理削除。ゴミ箱から復元または確認後に完全削除。
- **端末設定:** theme、mobile menu、sidebar width を `sharedMemoV3.*` の localStorage に保存。業務データは保存しない。

## 配信・外部依存

- 想定配信: GitHub Pages の `/docs` または静的 HTTP server。
- 実行時依存: Firebase JavaScript SDK 11.10.0、marked 16.1.1、DOMPurify 3.2.6（URL で固定）。
- backend: Firebase Authentication / Cloud Firestore。Firebase Hosting、Cloud Functions 設定はない。
- CI/CD、build、環境別設定、Firestore index 定義はない。

## 変更時に守る境界

- Rules による group membership と監査フィールド検証。
- Markdown を HTML 表示する前の sanitize。
- 旧 document の正規化と互換性（廃止するなら移行計画が必要）。
- 作成/更新時の UID と `serverTimestamp()`。
