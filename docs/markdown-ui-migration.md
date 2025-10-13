# MarkdownUI 導入計画

## 目的
- オーバーレイの Markdown プレビューを自前実装から [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) へ置き換え、CommonMark 対応とメンテナンス性を向上させる。
- 表、脚注、リンク、リストなどの表現力を高めつつ、SattoPad の軽快な表示とテーマを維持する。

## 導入ステップ
1. **依存追加（完了）**
   - Swift Package Manager に `https://github.com/gonzalezreal/MarkdownUI.git` を登録済み。CI や Homebrew フォーミュラに追加が必要なら別途反映する。
2. **レンダリング置換（完了）**
   - `OverlayPreviewView` 内の自前 MarkdownParser 呼び出しを MarkdownUI の `Markdown` ビューへ置換済み。
   - 自前のリスト描画ロジックは撤去し、MarkdownUI のデフォルトスタイルとテーマ拡張で調整。
3. **テーマ調整**
   - `OverlayTypography` に `Theme.sattoPad` を定義し、ベースフォントサイズ (`OverlaySettingsStore.fontSize`) を反映。
   - 背景や角丸は既存のラッパー (RoundedRectangle など) を継続使用。
4. **スクロールと調整モード対応（要確認）**
   - 現在の `ScrollView` コンテナを維持し、MarkdownUI ビューを child として埋め込む。
   - 調整モード時のスクロールバー表示と操作感を確認し、必要に応じてスクロール位置永続化を追加する。
5. **不要コードの整理（進行中）**
   - `MarkdownRenderer.swift` を削除済み。今後は `OverlayTypography` のテーマ設定を見直し、追加の不要プロパティがあれば削除する。
   - `OverlayPreviewView` のブロック生成ロジックを MarkdownUI ベースに置き換え済み。
6. **ドキュメント更新**
   - `docs/overlay-architecture.md` と `docs/hotkey-strategy.md` に表示レンダラの変更を記載。
   - `README.md` や `AGENTS.md` に MarkdownUI 採用について追記。

## コミット前チェックリスト
- [x] `OverlayPreviewView` が MarkdownUI の `Markdown` ビューで動作し、フォントサイズ設定が反映される。
- [x] 不要になった `MarkdownRenderer.swift` と関連ヘルパーを削除した。
- [ ] スクロール位置の永続化が必要か確認し、必要なら実装または別タスクに切り出す。
- [ ] 明暗両テーマで視認性を確認し、必要に応じ `MarkdownTheme` をカスタマイズした。
- [ ] 主要ドキュメント（`README.md`、`AGENTS.md`、`docs/overlay-architecture.md`、`docs/hotkey-strategy.md`）を更新した。
- [ ] `xcodebuild -scheme SattoPad build` でビルドし、ホットキー経由でもオーバーレイが期待通り描画されることを手動確認した。
- [ ] 変更点をスクリーンショットまたは動画でキャプチャし、PR 説明に添付できる状態にした。

## テスト計画
- 表／箇条書き／番号付きリスト／タスクリスト／リンク／コードブロックを含む Markdown を用意して表示確認。
- ホットキー表示／ポップオーバー表示双方でのパフォーマンス（表示まで 50ms 以内）と CPU 負荷を手動計測。
- `OverlaySettingsStore.fontSize` を変更した際に即時反映されるか検証。
- 外部ファイル変更→再読み込み時に MarkdownUI ビューが正常更新されるかを確認。

## リスクと対応
- **パフォーマンス低下**: 初期表示が重い場合はレンダラをキャッシュするか、テキスト変化時のみリレンダリングする。
- **スタイル差異**: 自前レンダラとの差分をスクリーンショットで比較し、必要なら `MarkdownTheme` を上書き。
- **アクセシビリティ**: ダークモードでのコントラスト確認。必要に応じ `DynamicTypeSize` や `Environment` を調整。

## ロールアウト
- フィーチャーブランチ `feature/markdownui-overlay` 上で作業し、UI 差分レビュー用のスクリーンショットを添付する。
- コミットメッセージ例: `feat: adopt MarkdownUI for overlay preview`。
- マージ前に `docs/` と `AGENTS.md` を更新し、破壊的変更がないことを周知する。
