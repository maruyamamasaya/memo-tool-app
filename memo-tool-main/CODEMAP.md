# Code Map

全ファイル一覧ではなく、検索を始めるための地図。正確な名前が不明なら **Search keywords** を semantic/repository search に渡し、名前を得た後に exact/symbol/reference search へ切り替える。

## Authentication and group authorization
- **Primary paths:** `docs/shared-memo/app.js`, `docs/shared-memo/firebase-config.js`, `firestore.rules`
- **Search keywords:** `onAuthStateChanged`, `signInWithPopup`, `enter`, `isGroupMember`, `defaultGroupId`, `members`
- **Key entry points:** `start()`, `enter()`, Rules の `isGroupMember()`
- **Related tests:** `tests/firestore-rules.test.mjs`、`desktop/test/auth-bridge.test.cjs` と `TESTING.md` の認証確認

## Memo editing, storage, and synchronization
- **Primary paths:** `docs/shared-memo/app.js`, `firestore.rules`
- **Search keywords:** `saveEditor`, `editorParts`, `listen`, `onSnapshot`, `memos`, `validMemo`, `serverTimestamp`
- **Key entry points:** `saveEditor()`, `listen()`, `normalize()`、Rules の `/memos/{memoId}`
- **Related tests:** static verify、`TESTING.md` のメモ/同期確認

## Folders, tags, filtering, and bulk actions
- **Primary paths:** `docs/shared-memo/app.js`, `docs/shared-memo/index.html`, `firestore.rules`
- **Search keywords:** `filteredMemos`, `renderFolders`, `saveFolder`, `deleteFolder`, `moveSelected`, `tags`, `folderId`
- **Key entry points:** `render()`, `filteredMemos()`, `saveFolder()`, `deleteFolder()`
- **Related tests:** static verify、`TESTING.md` の一覧・フォルダ・一括操作確認

## Rendering, responsive UI, themes, and Markdown
- **Primary paths:** `docs/shared-memo/index.html`, `docs/shared-memo/style.css`, `docs/shared-memo/app.js`
- **Search keywords:** `renderViewerBody`, `renderedMarkdown`, `DOMPurify`, `marked`, `THEMES`, `mobile`, `sidebar`
- **Key entry points:** HTML の `app.js` module、`renderViewerBody()`, `applyTheme()`, `bindSidebarResize()`
- **Related tests:** static verify、`TESTING.md` の UI/Markdown/レスポンシブ確認

## Runtime configuration and operations
- **Primary paths:** `docs/shared-memo/firebase-config.js`, `firestore.rules`, `OPERATIONS.md`
- **Search keywords:** `firebaseConfig`, `defaultGroupId`, `sharedMemoV3.`, CDN URL, `rules_version`
- **Key entry points:** `firebaseConfig`, `defaultGroupId`, `firestore.rules`
- **Related tests:** `scripts/verify.sh`、Firebase Console/Emulator の確認

## Searchability notes

機能ごとの directory や DB access layer はなく、`app.js` が UI と Firestore 操作を一括して持つ。現在は小規模だが、検索結果が同じ単一ファイルへ集中する。機能変更で分割が必要になった時に限り、イベント binding・表示・永続化の責務分割を ADR とともに検討し、検索性だけを理由に大規模 rename はしない。環境変数は使わず、公開クライアント設定は `firebaseConfig` に集約されている。

## Cross-device workflow and desktop
- **Primary paths:** `docs/shared-memo/memo-options.mjs`, `desktop/main.cjs`, `desktop/preload.cjs`, `desktop/auth-bridge.cjs`
- **Search keywords:** `memoOptions`, `parseRawMemo`, `googleLogin`, `desktopLogin`, `memoDesktop`, `createAuthBridge`
- **Related tests:** `tests/memo-options.test.mjs`, `desktop/test/auth-bridge.test.cjs`
