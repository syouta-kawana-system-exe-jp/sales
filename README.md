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

### 1. 基本: 1コマンドで分析（推奨）

```bash
python scripts/inbox.py ~/Downloads/IRIS提案書.pptx
```

これだけで以下が自動実行されます:
1. ファイルを `00_inbox/` にコピー
2. テキスト抽出 → Claude Opus 分析
3. 正しいフォルダーへ移動 + ナレッジ更新
4. commit & push

### 2. 複数ファイルを一括分析

```bash
python scripts/inbox.py ~/Downloads/提案書.pptx ~/Downloads/見積書.xlsx
```

### 3. 高速分析（Sonnet モデル）

軽い資料で速度優先の場合:

```bash
python scripts/inbox.py --model sonnet 軽い資料.pptx
```

### 4. ドライラン（分類だけ確認、ファイル移動なし）

```bash
python scripts/inbox.py --dry-run ファイル.pptx
```

### 5. inbox に既にあるファイルを分析

```bash
python scripts/analyze-local.py              # フル分析（Opus）
python scripts/analyze-local.py --dry-run    # 分類のみ
python scripts/analyze-local.py --model sonnet  # Sonnet で高速分析
```

---

## Codespaces で使う

リポジトリを Codespaces で開くと、分析環境が自動セットアップされます。

### 初回セットアップ

1. リポジトリページ → Code → Codespaces → Create codespace on main
2. ターミナルで `claude` を起動して OAuth ログイン

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

## セットアップ

### 必要なソフトウェア

| ソフトウェア | 用途 | インストール |
|---|---|---|
| **Python 3.13+** | テキスト抽出・スクリプト実行 | [python.org](https://www.python.org/downloads/) |
| **python-pptx** | PowerPoint テキスト抽出 | `pip install python-pptx` |
| **openpyxl** | Excel テキスト抽出 | `pip install openpyxl` |
| **PyPDF2** | PDF テキスト抽出 | `pip install PyPDF2` |
| **Node.js 20+** | Claude Code CLI の実行基盤 | [nodejs.org](https://nodejs.org/) |
| **Claude Code CLI** | AI 分析エンジン | `npm install -g @anthropic-ai/claude-code` |
| **Git** | バージョン管理・push | [git-scm.com](https://git-scm.com/) |
| **Claude MAX** | サブスクリプション（OAuth 認証） | [claude.ai](https://claude.ai/) |

### 一括インストール（Python パッケージ）

```bash
pip install python-pptx openpyxl PyPDF2
```

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
| `claude` コマンドが認証エラー | `claude` を単体で起動して OAuth 再ログイン |
| 分類が間違っている | `--dry-run` で分類理由を確認。手動で `git mv` して修正後、ナレッジも手動更新 |
| ファイルが inbox に残っている | 判定不能と判断されたファイル。Claude と対話モードで手動分析するか、ファイル名を分かりやすくしてリトライ |
| テキスト抽出エラー | `pip install --force-reinstall python-pptx openpyxl PyPDF2` で再インストール |

### API Key で完全自動化したい場合

Anthropic API Key を取得すれば、push だけで CI 上で自動分析が可能です。
`.github/workflows/analyze-with-api.yml.example` を参照してください。
