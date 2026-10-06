# Operations

起動・設定・deploy の正本。製品操作は [`README.md`](README.md) を参照する。

## Local static server

repository root で次を実行し、`http://localhost:8000/docs/shared-memo/` を開く。
```sh
python3 -m http.server 8000
```
`file://` ではなく HTTP で確認する。Firebase と CDN を使う統合確認には network 接続、設定済み Firebase project、Authentication authorized domain、group membership が必要。

## Firebase configuration
- 公開 Web client 設定と固定 group は `docs/shared-memo/firebase-config.js`。
- Google Authentication を有効化し、利用 host を Authorized domains に追加する。
- `groups/group001.members` は信頼された管理経路で管理する。アプリに管理 UI はない。
- service account や管理秘密鍵は repository に置かない。

## Deployment
- 静的 asset は GitHub Pages の `/docs` 配信を想定する。
- app と同時に root の `firestore.rules` を対象 Firebase project へ deploy する。
- repository 内に CI/CD、Firebase CLI project mapping、production URL の正本はないため、対象 project と稼働 revision を運用担当者が確認する。推測して deploy しない。
- deploy 前後の検証は [`TESTING.md`](TESTING.md) に従う。

## Current publishing target

GitHub Pages APIで`maruyamamasaya/memo-tool`の`main` `/docs`配信を確認。アプリURLは https://maruyamamasaya.github.io/memo-tool/shared-memo/ 。Firebase対象は`shared-memo-63202`。任意のusage/confidential/contentKindフィールドを許可するRulesを先に検証・配信してからWebを公開する。旧データと旧クライアントの更新互換性を維持する。

常駐アプリは[desktop/README.md](desktop/README.md)の通り既存Webを読み込む。更新時はWeb公開後、既存ウィンドウを再読み込みして認証連携を検証する。

Macログインが旧popup経路で止まる場合は、最新の常駐アプリでShared Memoメニューの「再読み込み」を選ぶ。GoogleでログインするとChromeに同じWebが開き、「常駐アプリへログイン」から認証する。成功時はアプリが同期済みになる。認証リンクは3分で失効するため、失効時はアプリから再実行する。
