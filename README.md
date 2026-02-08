# 営業ドキュメント管理 & 自動ナレッジ分析システム

複数顧客向けIT提案書・見積書の管理と、社内ナレッジベースの自動構築を行うリポジトリ。

## クイックスタート

### ファイルを追加する（自動分析）

```bash
# 1. ファイルを 00_inbox/ に置く
cp ~/Downloads/IRIS次期提案書.pptx 00_inbox/

# 2. push するだけ
git add 00_inbox/
git commit -m "add: IRIS次期提案書"
git push
```

push 後、GitHub Actions が自動で以下を実行します:
- ファイル内容を読み取って分類判定
- 正しいフォルダーへ移動（`git mv`）
- ナレッジベース（案件カタログ・見積パターン集等）を更新
- 結果を auto-commit & push

**Actions タブ** で進捗とログを確認できます。

---

## フォルダー構成

```
00_inbox/              ← ここにファイルを置く（自動仕分けの入口）
01_clients/
  ├── 01_idemitsu/       出光興産
  │   ├── 01_proposals/    提案書
  │   ├── 02_estimates/    見積書
  │   └── 03_management/   管理資料（実行予算・WBS・検証シート等）
  └── NN_<顧客名>/        新規顧客は自動で連番作成
      ├── 01_proposals/
      ├── 02_estimates/
      └── 03_management/
02_knowledge/
  ├── 01_proposal_cases/   案件カタログ・提案ナレッジ（顧客別）
  ├── 02_training/         教育資料
  ├── 03_standards/        PMBOK・非機能要求グレード等
  ├── 04_introductions/    会社紹介・技術紹介
  ├── 05_reviews/          レビューナレッジ
  └── 06_estimate_patterns/ 見積パターン集
```

## 分類ルール

ファイルは **内容を精読** して以下の優先順位で分類されます（ファイル名だけでは判断しない）:

| 優先度 | 分類 | キーワード例 |
|:---:|---|---|
| 1 | 管理資料 | 検証シート・実行予算・WBS・スケジュール・計画書 |
| 2 | 提案書 | 提案・ご提案・構想書・キックオフ |
| 3 | 見積書 | 見積・概算・工数算出・費用・粗利 |
| 4 | 紹介資料 | 会社案内・サービス紹介・AI技術 |
| 5 | 教育資料 | 教育・研修・トレーニング |
| 6 | 規格資料 | PMBOK・規格・ガイド |

**顧客の判定:**
- テキスト内容・ファイル名から顧客を自動判定
- 出光興産: 「出光」またはシステム名（IRIS, SWAN, HUB, MES 等）
- 新規顧客: 自動で `01_clients/NN_<顧客名>/` フォルダーを作成
- 顧客不明: `00_inbox/` に残して報告（手動で確認後リトライ）

---

## 使い方

### 1. 基本: push で自動分析（推奨）

```bash
cp ファイル.pptx 00_inbox/
git add 00_inbox/ && git commit -m "add: ファイル名" && git push
```

デフォルトは **Sonnet**（高速・低コスト）で分析されます。

### 2. 高品質分析: Actions から手動実行

精度が重要なファイル（大規模見積書、複雑な提案書）の場合:

1. Actions タブ →「**Analyze Inbox Files**」を選択
2. 「**Run workflow**」をクリック
3. モデルを `claude-opus-4-6` に変更
4. 「**Run workflow**」で実行

### 3. ドライラン: 分類だけ確認（ファイルは移動しない）

ローカルまたは Codespaces で:

```bash
# テキスト抽出
python scripts/extract_text.py

# 分類結果を JSON で確認（ファイル移動なし）
claude -p "$(cat scripts/prompts/classify-only.txt)

## 抽出済みテキストデータ
$(cat extracted_texts.json)" --max-turns 1
```

### 4. ローカルでフル分析

```bash
python scripts/extract_text.py
claude -p "$(cat scripts/prompts/analyze-file.txt)

## 抽出済みテキストデータ
$(cat extracted_texts.json)"
```

---

## Codespaces で使う

リポジトリを Codespaces で開くと、分析環境が自動セットアップされます。

### 初回セットアップ

1. [GitHub Settings > Codespaces](https://github.com/settings/codespaces) で `ANTHROPIC_API_KEY` を登録
2. リポジトリページ → Code → Codespaces → Create codespace on main

詳細は [.devcontainer/README.md](.devcontainer/README.md) を参照。

---

## ナレッジベースの活用

蓄積されたナレッジを検索・活用する手順:

```bash
# 1. 全体像を把握
claude "案件横断サマリーを読んで、出光興産の案件傾向を教えて"

# 2. 特定案件を調べる
claude "IRISの提案書と見積書を一覧にして"

# 3. 類似案件を探す
claude "クラウド移行の見積パターンを比較して"

# 4. 新しい提案の参考にする
claude "Azure移行の過去提案を参考に、新規提案の構成案を作って"
```

### ナレッジファイル一覧

| ファイル | 内容 | サイズ |
|---|---|---|
| 案件横断サマリー_出光興産.md | 全案件の横断分析・活用ガイド | 16KB |
| 案件カタログ_出光興産.md | 39案件のファイルインデックス | — |
| 提案書ナレッジ_出光興産.md | 19件の提案書全文テキスト | 335KB |
| 見積書ナレッジ_出光興産.md | 144件の見積書全文テキスト | 1.6MB |
| 管理資料ナレッジ_出光興産.md | 112件の管理資料全文テキスト | 514KB |
| 見積パターン集.md | パターン別見積構造・共通ポイント | — |

---

## コスト目安

| シナリオ | モデル | 概算コスト |
|---|---|---|
| 小さい pptx（4スライド） | Sonnet | ~$0.02 |
| 大きい xlsx（13シート） | Sonnet | ~$0.12 |
| 深い分析 + クロスリファレンス | Opus | ~$1.00 |
| 5ファイル一括 | Sonnet | ~$0.40 |

---

## セットアップ（管理者向け）

### 必要な設定

1. **GitHub Secrets** に `ANTHROPIC_API_KEY` を追加
   - Settings → Secrets and variables → Actions → New repository secret

2. **Actions の権限** を確認
   - Settings → Actions → General → Workflow permissions → Read and write permissions

### 対応ファイル形式

| 形式 | ライブラリ | 抽出内容 |
|---|---|---|
| .pptx | python-pptx | スライド・テキストフレーム・テーブル |
| .xlsx / .xlsm | openpyxl | 全シート・セル（500行/シート上限） |
| .pdf | PyPDF2 | ページテキスト |
| その他 | — | ファイル名から分類（内容分析なし） |

### トラブルシューティング

| 症状 | 対処 |
|---|---|
| Actions が起動しない | `00_inbox/` 配下にファイルが push されているか確認。`.gitkeep` のみの変更ではトリガーしない |
| 分類が間違っている | Actions ログで分類理由を確認。手動で `git mv` して修正後、ナレッジも手動更新 |
| ファイルが inbox に残っている | 判定不能と判断されたファイル。ローカルの Claude Code で手動分析するか、ファイル名を分かりやすくしてリトライ |
| API エラー | Secrets の `ANTHROPIC_API_KEY` が有効か確認。API 利用上限に達していないか確認 |
