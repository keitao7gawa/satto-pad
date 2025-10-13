# 直近で対応すべき修正

## 1. ホットキーのみで起動した際にメモが読み込まれない問題
- 現在 `MarkdownStore.shared.loadOnLaunch()` を呼んでいるのは `ContentView` の `onAppear` 内だけ。つまりポップオーバーを開かない限りディスクからメモを読み込まない。
- ユーザーがアプリ起動後にいきなりグローバルホットキーを押すと、オーバーレイに空のテキストが表示されてしまう。
- 対応方針: `applicationDidFinishLaunching`（または同等の起動直後フック）で `MarkdownStore.shared.loadOnLaunch()` を一度呼び、オーバーレイ・ポップオーバー双方が最新メモ状態になるようにする。必要なら AppDelegate から呼び出す。

## 参考
- 修正後は `AGENTS.md` のホットキー/オーバーレイ運用節にも反映し、初期ホットキーとロードタイミングの仕様を明記する。
