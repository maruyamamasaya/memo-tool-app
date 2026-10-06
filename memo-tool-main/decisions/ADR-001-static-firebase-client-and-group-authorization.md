---
status: accepted
date: 2026-08-28
---

# ADR-001: 静的 Firebase クライアントとグループ認可を維持する

## Context

knowledge bootstrap 時に、初期実装（commit `9151b64`）、現行コード、README、Rules から確認できる範囲を遡って記録した。初期 README は GitHub Pages 向けで、将来の SwiftUI クライアントとも Firestore collection を共有する構成を明記していた。独自 backend を設けなかった当時の詳細な比較検討や意思決定者は履歴から確認できない。

現行アプリは静的 HTML/CSS/JavaScript から Firebase Authentication と Firestore を直接使用する。既定 group は `group001` で、membership は `groups/{groupId}.members` の UID 配列に置く。

## Decision

- GitHub Pages で配信可能な静的クライアントとし、認証・永続化・リアルタイム同期には Firebase を直接利用する。
- セキュリティ境界はクライアント判定ではなく `firestore.rules` とする。
- memos/folders は `groupId` で分離し、対象 group の members に認証 UID がある場合だけ操作可能にする。
- group/member はクライアントから変更させず、信頼された管理経路で管理する。
- 監査フィールド、UID、server timestamp、更新可能フィールドを Rules で検証する。

## Consequences

- 静的配信だけで動作し、専用 API server の運用は不要。同じデータモデルを別クライアントから再利用できる。
- Firebase Web 設定は公開されるため、Rules の検証と deploy が必須。
- 現在は単一固定 group で、group 選択やメンバー管理 UI はない。
- Rules で表現しにくい処理や大規模 query が必要なら別 ADR で再評価する。

## Evidence

- `docs/shared-memo/app.js`: Firebase 直接利用、membership 事前確認、group 条件の購読。
- `docs/shared-memo/firebase-config.js`: Firebase Web 設定と固定 group。
- `firestore.rules`: members ベースの認可と監査フィールド検証。
- `README.md` と commit `9151b64`: GitHub Pages と cross-client data reuse の記述。
