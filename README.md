# SattoPad - 瞬間メモアプリ

⚡ **ホットキー入力中にのみ，一瞬でメモを表示**

> 「さっと」みることに全振りした、超シンプルな macOS 用メモアプリ

[![Download](https://img.shields.io/badge/Download-macOS%2012+-blue?style=for-the-badge&logo=apple)](https://github.com/keitao7gawa/satto-pad/releases)
[![GitHub stars](https://img.shields.io/github/stars/keitao7gawa/satto-pad?style=for-the-badge&logo=github)](https://github.com/keitao7gawa/satto-pad)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge)](https://github.com/keitao7gawa/satto-pad/actions)

---

![Satto-pad-concept](https://github.com/user-attachments/assets/1ce848d7-333d-4996-891f-6ae8e3a95abb)

---

## 📥 ダウンロード

### システム要件
- **macOS 12.0+** (Monterey以降)
- **Apple Silicon** または **Intel** プロセッサ

### インストール方法

#### 1. GitHub Releases（推奨）
```bash
# 最新リリースをダウンロード
curl -L https://github.com/keitao7gawa/satto-pad/releases/latest/download/SattoPad.dmg
```

#### 2. Homebrew
```bash
brew install --cask satto-pad
```

#### 3. 手動インストール
1. [Releases](https://github.com/keitao7gawa/satto-pad/releases)から最新版をダウンロード
2. `.dmg`ファイルを開く
3. アプリを`Applications`フォルダにドラッグ
4. 初回起動時にセキュリティ設定を許可

---

## 🚀 なぜSattoPadなのか？

| 機能 | SattoPad | 他のメモアプリ |
|------|----------|----------------|
| **操作** | `ホットキー長押し` | クリック・タップ・ホットキートグル |
| **表示方式** | `オーバーレイ` | ウィンドウ切り替え |
| **データ保存** | `ローカルのみ` | クラウド同期 |
| **学習コスト** | ほぼゼロ | 設定が必要 |

### 🎯 1つのことに特化
- **見る**ことが主役、書くことは最短で済ませる
- 脱線を防ぎ、今の立ち位置を「すぐ見たい」

---

## ⚡ 使い方

### 1️⃣ ホットキーで「見る」
```
Cmd + Shift + T を長押し
```
- 押している間だけオーバーレイが表示
- 離すと自動で非表示

### 2️⃣ 必要なら「書く」
```
メニューバーアイコンをクリック
```
- ポップオーバーで編集
- 自動保存（1秒デバウンス）

---

## 🎨 主な機能

### ⚡ 瞬間表示
- **メニューバー常駐** + **グローバルショートカット**
- 押している間だけ表示できるオーバーレイ
- 0.3秒での表示・非表示

### 🎯 シンプルな操作
- **シンプルな複数行メモ** + **軽いプレビュー**
- **Markdown自動保存**・起動時復元（ローカルのみ）
- **UIは最小限**：見る→必要なら一言書く→閉じる

### 🔧 カスタマイズ
- **透明度調整**：5%〜100%（ヘッダーのスライダー）
- **オーバーレイ移動**：ドラッグで位置調整
- **保存先変更**：3点メニューから任意の場所に設定

---

## 🔒 プライバシー

- ✅ **すべてローカル保存**
- ✅ **クラウドや外部送信なし**
- ✅ **オープンソース**（MIT License）
- ✅ **サンドボックス対応**

---

## 👨‍💻 開発者情報

**開発者**: [@keitao7gawa](https://github.com/keitao7gawa)  
**方針**: シンプルで実用的なツールの提供

### 技術スタック
- **SwiftUI** - モダンなUI
- **AppKit** - ネイティブmacOS統合
- **KeyboardShortcuts** - グローバルショートカット
- **Carbon** - フォールバック対応

### 依存関係
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