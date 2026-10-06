# Copy feedback

## Request

メモ表示画面でコピー完了が分かるようにする。

## Investigation

コピー成功時の共通メッセージは非表示になるため、表示画面上で成功を確認できなかった。

## Changes

コピー成功後、表示画面のボタンを 1.8 秒間「コピーしました」に変更し、連打を防ぐ間は無効化するようにした。

## Validation

`verify.sh` が呼び出す static asset / DOM ID / JavaScript 構文と Markdown link の各 check、`git diff --check` を実行し、すべて通過した。この環境では Firebase 認証済みブラウザでの手動確認は実施していない。

## Result

コピー操作の成功が表示画面内で分かるようになった。

## Remaining Issues

なし。
