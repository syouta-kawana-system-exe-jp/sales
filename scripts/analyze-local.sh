#!/bin/bash
# analyze-local.sh — ローカル環境で inbox ファイルの分析を実行する
#
# Claude MAX 認証済みの環境で使用。API Key 不要。
#
# 使い方:
#   ./scripts/analyze-local.sh                    # フル分析（分類+移動+ナレッジ更新）
#   ./scripts/analyze-local.sh --dry-run          # 分類のみ（ドライラン）
#   ./scripts/analyze-local.sh --model opus       # Opus で高品質分析

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# デフォルト設定
MODEL="claude-opus-4-6"
MAX_TURNS=30
DRY_RUN=false

# 引数パース
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --model)
      case "$2" in
        opus)   MODEL="claude-opus-4-6" ;;
        sonnet) MODEL="claude-opus-4-6" ;;
        *)      MODEL="$2" ;;
      esac
      shift 2 ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
done

# inbox にファイルがあるか確認
INBOX_FILES=$(find 00_inbox/ -type f ! -name '.gitkeep' 2>/dev/null || true)
if [ -z "$INBOX_FILES" ]; then
  echo "00_inbox/ にファイルがありません。"
  echo "使い方: ./scripts/inbox.sh <ファイル> でファイルを追加してください。"
  exit 0
fi

echo "=== 対象ファイル ==="
echo "$INBOX_FILES"
echo ""

# Step 1: テキスト抽出
echo "=== Step 1: テキスト抽出 ==="
python scripts/extract_text.py
echo ""

# 抽出データの読み込み
EXTRACTED_PATH="extracted_texts.json"
if [ -f /tmp/extracted_texts.json ]; then
  EXTRACTED_PATH="/tmp/extracted_texts.json"
fi

if [ ! -f "$EXTRACTED_PATH" ]; then
  echo "エラー: テキスト抽出結果が見つかりません" >&2
  exit 1
fi

# Step 2: プロンプト構築
PROMPT_FILE=$(mktemp)
if [ "$DRY_RUN" = true ]; then
  cat scripts/prompts/classify-only.txt > "$PROMPT_FILE"
  MAX_TURNS=1
  echo "=== Step 2: 分類のみ（ドライラン） ==="
else
  cat scripts/prompts/analyze-file.txt > "$PROMPT_FILE"
  echo "=== Step 2: フル分析 ==="
fi

# 抽出データをプロンプトに追加
{
  echo ""
  echo "---"
  echo "## 抽出済みテキストデータ"
  echo ""
  echo '```json'
  cat "$EXTRACTED_PATH"
  echo '```'
} >> "$PROMPT_FILE"

echo "モデル: $MODEL"
echo "最大ターン: $MAX_TURNS"
echo ""

# Step 3: Claude 分析実行
echo "=== Step 3: Claude 分析実行 ==="
claude -p "$(cat "$PROMPT_FILE")" \
  --model "$MODEL" \
  --max-turns "$MAX_TURNS"

# クリーンアップ
rm -f "$PROMPT_FILE"
if [ -f "extracted_texts.json" ]; then
  rm -f "extracted_texts.json"
fi

# Step 4: ドライランでなければ commit & push
if [ "$DRY_RUN" = false ]; then
  echo ""
  echo "=== Step 4: コミット & プッシュ ==="
  git add -A
  if git diff --cached --quiet; then
    echo "変更なし（コミット不要）"
  else
    git commit -m "auto: inbox ファイルを分析・分類

モデル: $MODEL"
    git push
    echo "push 完了。"
  fi
fi
