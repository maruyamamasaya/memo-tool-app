# Shared Memo Desktop

既存Web版を読み込むMac/Windows常駐アプリ。Googleログインはシステムブラウザで行い、短時間・一度限りのlocalhostコールバックを経由して常駐アプリへ引き継ぐ。ブラウザで「常駐アプリへログイン」を押し、完了後に常駐ウィンドウを確認する。

- メニューバー／通知領域のアイコンから開く。閉じるボタンは非表示、メニューの終了で終了。
- `Cmd/Ctrl+Shift+M`で表示切替。競合時はアプリメニューに登録不可と表示する。
- 本文やクリップボードを監視しない。コマンドを実行しない。
- HTTPSの既存公開サイトだけがnative bridgeを利用でき、外部リンクはブラウザへ送る。
- 配布ZIPは署名・公証なしの試作。Macはarm64、Windowsはx64。Windows実機確認は別途必要。

## 開発とビルド

Node 22以上で`npm ci`、`npm test`、`npm start`。
`npm run build:mac`と`npm run build:win`で`dist`にZIPを作成する。
公開Webに`memoDesktop`連携が反映されてから利用する。
