# Codespaces / Dev Container セットアップガイド

## 概要

このリポジトリは GitHub Codespaces で開くと、営業ドキュメントの分析環境が自動的にセットアップされます。

## セットアップ手順

### 1. Anthropic API Key の設定

GitHub の Codespaces 設定で環境変数を追加してください:

1. [GitHub Settings > Codespaces](https://github.com/settings/codespaces) を開く
2. 「New secret」をクリック
3. Name: `ANTHROPIC_API_KEY`
4. Value: Anthropic API キーを入力
5. Repository access: このリポジトリを選択

### 2. Codespace の起動

1. リポジトリページで「Code」→「Codespaces」→「Create codespace on main」
2. 自動で Python 3.13 + Node.js 20 + Claude Code CLI がインストールされます

### 3. Claude Code の認証

Codespace のターミナルで:

```bash
# API Key が設定されていることを確認
echo $ANTHROPIC_API_KEY

# Claude Code の動作確認
claude --version
```

## 使い方

### ファイルの手動分析

```bash
# 1. テキスト抽出
python scripts/extract_text.py

# 2. 分類のみ（ドライラン）
claude -p "$(cat scripts/prompts/classify-only.txt)" --max-turns 1

# 3. フル分析（分類 + 移動 + ナレッジ更新）
claude -p "$(cat scripts/prompts/analyze-file.txt)"
```

### GitHub Actions による自動分析

`00_inbox/` にファイルを push するだけで自動的に分析が実行されます。

```bash
# ファイルを inbox に追加
cp ~/Downloads/新しい提案書.pptx 00_inbox/
git add 00_inbox/
git commit -m "add: 新しい提案書"
git push
```

Actions タブでワークフローの実行状況を確認できます。

### 手動トリガー（モデル選択可能）

Actions タブから「Analyze Inbox Files」→「Run workflow」で手動実行できます。
高品質な分析が必要な場合は `claude-opus-4-6` を選択してください。

## 含まれるツール

| ツール | バージョン | 用途 |
|---|---|---|
| Python | 3.13 | テキスト抽出スクリプト実行 |
| python-pptx | latest | PowerPoint テキスト抽出 |
| openpyxl | latest | Excel テキスト抽出 |
| PyPDF2 | latest | PDF テキスト抽出 |
| Node.js | 20 | Claude Code CLI 実行基盤 |
| Claude Code CLI | latest | AI 分析エンジン |

## トラブルシューティング

### API Key が認識されない

```bash
# 環境変数を確認
env | grep ANTHROPIC

# 手動で設定（一時的）
export ANTHROPIC_API_KEY="sk-ant-..."
```

### テキスト抽出でエラーが出る

```bash
# 依存パッケージの再インストール
pip install --force-reinstall python-pptx openpyxl PyPDF2
```
