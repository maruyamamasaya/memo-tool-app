# ロードマップ1–6の実装・検証記録（2026-10-07）

実装用プロンプトは [IMPLEMENTATION_PROMPT.md](IMPLEMENTATION_PROMPT.md)。Webの正本は https://github.com/maruyamamasaya/memo-tool 、このリポジトリのmemo-tool-mainは同日時点の同期コピー。

1. 既存SwiftDataストア移行、本文・フォルダ・タグ保持、ゴミ箱・復元を実モデルの回帰実行で確認。
2. 一時/保存・機密・固定を独立した任意フィールドとして追加。旧データの既定は保存/公開/メモ。
3. タイトル省略で本文をそのまま保存、明示的な保存状態と失敗時再試行。Webの保存・コピーで空白、改行、末尾#行保持を確認。
4. プロンプト/コマンド/コード分類、機密本文の検索除外。Webのモバイル表示とiOSの表示・分類を検証。
5. iOSテキスト/URL共有拡張を追加し、共有Keychainで既存Google認証を利用。最終Releaseアーカイブと開発用IPA書き出し成功。認証付き実機共有は未確認。
6. Mac arm64/Windows x64常駐試用版ZIPを作成。Mac起動、閉じて常駐、ショートカット表示、Chrome認証からの復帰と「同期済み」を確認。Windows実行は未確認。

WebのNodeテスト6件とFirestore Emulatorテスト4件が成功。Firebase shared-memo-63202のRulesデプロイとGitHub Pages公開を確認。

既存iPhone17Pro Simulator F26F773A-A316-4610-9228-84217FEEB82Aを逐次再利用。XCTest device setの前後記録に追加なし。複製削除0、残存候補0。

成果物は親ディレクトリDistribution。Mac/Windowsは未署名の試用版、IPAは開発用でTestFlight/App Store公開は未実施。ログとSimulator記録は /private/tmp/memo-roadmap-validation に保存。
