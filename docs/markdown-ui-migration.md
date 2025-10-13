# MarkdownUI 導入計画

## 目的
- オーバーレイの Markdown プレビューを自前実装から [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) へ置き換え、CommonMark 対応とメンテナンス性を向上させる。
- 表、脚注、リンク、リストなどの表現力を高めつつ、SattoPad の軽快な表示とテーマを維持する。

## 導入ステップ
1. **依存追加**
   - Xcode の Swift Package Manager から `https://github.com/gonzalezreal/MarkdownUI.git` を追加。
   - ターゲット `SattoPad` にリンクし、CI／Homebrew フォーミュラの依存更新を忘れずに。
2. **レンダリング置換**
   - `OverlayPreviewView` 内の `MarkdownRenderer.parseMarkdownBlocks` 呼び出しを `Markdown` ビューへ置き換え。
   - 自前のリスト／タスクリスト表現と競合しないよう、MarkdownUI の `TaskListMarker` 表示を利用。
3. **テーマ調整**
   - `OverlayTypography` のフォント設定を MarkdownUI の `MarkdownTextStyle` にマッピングし、ベースフォントサイズ (`OverlaySettingsStore.fontSize`) を反映。
   - 背景や角丸は既存のラッパー (RoundedRectangle など) を継続使用。
4. **スクロールと調整モード対応**
   - 現在の `ScrollView` コンテナを維持し、MarkdownUI ビューを child として埋め込む。
   - スクロール位置保存／復元ロジックが機能するか確認し、必要なら `ScrollViewProxy` で再実装。
5. **不要コードの整理**
   - `MarkdownRenderer.swift`、関連ユーティリティ (`OverlayTypography` 内の Markdown 固有設定など) を削除または縮小。
   - `OverlayPreviewView` のブロック生成ロジックを整理し、MarkdownUI 導入後の簡潔な構造へ更新。
6. **ドキュメント更新**
   - `docs/autosave-system.md` は不要。`docs/overlay-architecture.md` と `docs/hotkey-strategy.md` に表示レンダラの変更を記載。
   - `README.md` や `AGENTS.md` に MarkdownUI 採用について追記。

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
- 段階的に実装: フィーチャーブランチ `feature/markdownui-overlay` を作成し、UI 差分レビュー用のスクリーンショットを添付。
- マージ前に `docs/` と `AGENTS.md` を更新し、破壊的変更がないことを周知。
