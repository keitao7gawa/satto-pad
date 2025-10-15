# SattoPad - 思考を止めない、あなたのための瞬間メモ

⚡ **ホットキー入力中にのみ，一瞬でメモを表示**

> 「考え事をしている時、一瞬だけメモを確認したい」「アプリを切り替える手間さえもどかしい」そんな悩みを解決する、禅の集中モードを提供するメモアプリ

[![Download](https://img.shields.io/badge/Download-macOS%2012+-blue?style=for-the-badge&logo=apple)](https://github.com/keitao7gawa/satto-pad/releases)
[![GitHub stars](https://img.shields.io/github/stars/keitao7gawa/satto-pad?style=for-the-badge&logo=github)](https://github.com/keitao7gawa/satto-pad)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge)](https://github.com/keitao7gawa/satto-pad/actions)

---

![Satto-pad-concept](https://github.com/user-attachments/assets/1ce848d7-333d-4996-891f-6ae8e3a95abb)

---

## 🚀 SattoPadが提供するユニークな体験

SattoPadは単なるメモアプリではありません。あなたのワークフローに溶け込み、思考を加速させるためのツールです。

### ⚡ 瞬間アクセス
**`Cmd + Shift + T` を長押しするだけ**。どのアプリを使っていても、必要な情報が目の前に現れます。キーを離せば、すぐに消える。このミニマルな体験が、あなたの集中力を維持します。

### 🧘 禅の集中モード
Dockやウィンドウは表示せず、メニューバーに静かに常駐。作業領域を一切邪魔しません。必要な時だけ、そっとあなたのそばに。

### ✍️ 書きたい時も、スムーズに
メニューバーアイコンをクリックすれば、Markdown対応の使い慣れたエディタですぐに書き込めます。もちろん、内容は自動で保存されるので安心です。

---

## 💎 主な機能と利点

### 🎯 コア機能
- **グローバルホットキー**: `Cmd + Shift + T` 長押しで、いつでもどこでもメモをオーバーレイ表示
- **自動保存**: 1秒間のデバウンスで入力を検知し、思考の断片を漏らさず保存します
- **外部変更の自動検知**: VS Codeなどのお気に入りエディタでファイルを直接編集しても、変更がリアルタイムにアプリへ反映されます

### ✨ 編集とカスタマイズ
- **Markdownサポート**: リストや見出しなど、基本的な記法に対応。思考を構造化するのに役立ちます
- **MarkdownUIプレビュー**: オーバーレイは [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) をベースに、SattoPad専用テーマで見出し・コード・チェックリストを読みやすく表示します
- **オーバーレイ非表示タグ**: ポップオーバーで残したいメモは `<!--@hide-->` 〜 `<!--@show-->` で囲むだけで、ホットキー表示のオーバーレイから除外できます
- **ローカル保存**: メモは `~/Documents/SattoPad.md` に安全に保存。シンプルで透明性の高い設計です
- **柔軟な設定**:
  - **保存先の変更**: あなたの好きな場所にメモファイルを置くことができます
  - **透明度・位置調整**: 画面に馴染むよう、オーバーレイの見た目を自由自在に
  - **ホットキーのカスタマイズ**: 他のアプリと競合しない、あなただけのショートカットを設定できます

---

## 🔧 技術的なこだわり

- **OS**: macOS 12.0+ (Monterey以降)
- **アーキテクチャ**: Apple Silicon (ARM64) & Intel (x86_64) 両対応のUniversal Binary
- **フレームワーク**: SwiftUIのモダンなUIとAppKitの堅牢なAPIを組み合わせ、ネイティブならではの軽快なパフォーマンスと安定性を実現しました
- **依存ライブラリ**: KeyboardShortcuts を活用し、信頼性の高いグローバルホットキー機能を提供しています

---

## 📥 今すぐ体験する

### 1. Homebrew
以下のコマンドでインストールできます

```bash
brew tap keitao7gawa/satto-pad
brew install --cask satto-pad
```

### 2. 手動ダウンロード
1. [GitHub Releases](https://github.com/keitao7gawa/satto-pad/releases) から最新の `SattoPad.dmg` をダウンロードしてください
2. DMGを開き、`SattoPad.app` を `Applications` フォルダにドラッグします
3. 初回起動時、アクセシビリティへのアクセス許可を求められた場合は、システム設定から許可してください

---

## 🎯 使い方

### 1️⃣ 見る（瞬間アクセス）
```
Cmd + Shift + T を長押し
```
- 押している間だけオーバーレイが表示
- 離すと自動で非表示
- 思考の流れを止めない、一瞬の確認

### 2️⃣ 書く（必要に応じて）
```
メニューバーアイコンをクリック
```
- ポップオーバーでMarkdown編集
- 自動保存（1秒デバウンス）
- 外部エディタとの連携も可能

---

## 🔒 プライバシー第一

あなたの思考やアイデアは、あなただけのものです。

- ✅ **完全ローカル**: データが外部サーバーに送信されることは一切ありません
- ✅ **オープンソース (MIT)**: 全てのコードはGitHubで公開されており、誰でもその安全性を確認できます

---

## 🚀 なぜSattoPadなのか？

| 機能 | SattoPad | 他のメモアプリ |
|------|----------|----------------|
| **操作** | `ホットキー長押し` | クリック・タップ・ホットキートグル |
| **表示方式** | `オーバーレイ` | ウィンドウ切り替え |
| **データ保存** | `ローカルのみ` | クラウド同期 |
| **学習コスト** | ほぼゼロ | 設定が必要 |
| **集中力維持** | `思考を止めない` | 作業フローを中断 |

### 🎯 1つのことに特化
- **見る**ことが主役、書くことは最短で済ませる
- 脱線を防ぎ、今の立ち位置を「すぐ見たい」
- 禅の集中モードで、あなたの創造的な時間を加速

---

## 👨‍💻 開発者情報

**開発者**: [@keitao7gawa](https://github.com/keitao7gawa)  
**方針**: シンプルで実用的なツールの提供

- **SwiftUI** - モダンなUI
- **AppKit** - ネイティブmacOS統合
- **MarkdownUI** - オーバーレイのMarkdownレンダリング
- **KeyboardShortcuts** - グローバルショートカット
- **Carbon** - フォールバック対応

### 依存関係
- `MarkdownUI` (MIT License)
- `KeyboardShortcuts` (MIT License)
- `SwiftUI` (Apple)
- `AppKit` (Apple)

---

## 🛠️ 開発者向け

### ビルド・実行
```bash
git clone https://github.com/keitao7gawa/satto-pad.git
cd satto-pad
open SattoPad.xcodeproj
```

**要件:**
- Xcode 15+
- macOS 12+ (開発環境)

### セキュリティスキャン結果
- ✅ **コード品質**: SwiftLint準拠
- ✅ **依存関係**: 脆弱性なし
- ✅ **サンドボックス**: 完全対応

---

## ❓ FAQ

**Q: 他のアプリと競合するホットキーは？**
A: 3点メニューから設定変更可能です。

**Q: データはどこに保存されますか？**
A: デフォルトは`~/Documents/SattoPad/SattoPad.md`です。変更可能。

**Q: 外部エディタで編集したファイルは？**
A: 自動検知してリロードします（未保存の変更がある場合は警告）。

**Q: サンドボックス環境でも動作しますか？**
A: はい。セキュリティスコープ付きブックマークで対応。

**Q: トラブルシューティング**
A: よくある問題と解決方法：
- ホットキーが効かない → システム環境設定でアクセシビリティ権限を確認
- アプリが起動しない → macOS 12.0以降であることを確認
- 保存ができない → ディスク容量と書き込み権限を確認

---

## 🌱 これからのSattoPad

このアプリはまだ始まったばかりです。あなたのフィードバックが、SattoPadをより良いツールへと成長させます。

## 🤝 コミュニティ

- 🐛 **バグ報告**: [Issues](https://github.com/keitao7gawa/satto-pad/issues)
- 💡 **機能要望**: [Discussions](https://github.com/keitao7gawa/satto-pad/discussions)
- 🐦 **Twitter**: [@keitao7gawa](https://twitter.com/keitao7gawa)
- 📧 **連絡先**: [GitHub Profile](https://github.com/keitao7gawa)

---

## 📄 ライセンス

MIT License - 詳細は[LICENSE](LICENSE)を参照

---

## ⭐ スターをください！

このプロジェクトが役に立ったら、ぜひスターを押してください！

[![GitHub stars](https://img.shields.io/github/stars/keitao7gawa/satto-pad?style=social&logo=github)](https://github.com/keitao7gawa/satto-pad)

---

**シンプルに、すぐ書ける。SattoPad は「取り出す/書く/閉じる」を最速にします。**
