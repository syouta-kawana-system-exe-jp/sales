#!/bin/bash
# inbox.sh — ファイル追加 → 分析 → コミット → push を1コマンドで実行
#
# 使い方:
#   ./scripts/inbox.sh ファイル1.pptx [ファイル2.xlsx ...]
#   ./scripts/inbox.sh --dry-run ファイル.pptx       # 分類のみ確認
#   ./scripts/inbox.sh --model sonnet ファイル.pptx    # Sonnet で高速分析

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$REPO_ROOT/00_inbox"

# オプションパース
ANALYZE_OPTS=()
FILES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)     ANALYZE_OPTS+=("--dry-run"); shift ;;
    --model)       ANALYZE_OPTS+=("--model" "$2"); shift 2 ;;
    *)             FILES+=("$1"); shift ;;
  esac
done

if [ ${#FILES[@]} -eq 0 ]; then
  echo "使い方: ./scripts/inbox.sh [オプション] <ファイル> [ファイル2 ...]"
  echo ""
  echo "オプション:"
  echo "  --dry-run        分類のみ確認（ファイル移動なし）"
  echo "  --model sonnet   Sonnet で高速分析（デフォルト: Opus）"
  echo ""
  echo "例:"
  echo "  ./scripts/inbox.sh ~/Downloads/IRIS提案書.pptx"
  echo "  ./scripts/inbox.sh --dry-run ~/Downloads/*.pptx"
  echo "  ./scripts/inbox.sh --model sonnet 軽い資料.pptx"
  exit 1
fi

# ファイルを 00_inbox/ にコピー
NAMES=()
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "エラー: $FILE が見つかりません" >&2
    exit 1
  fi
  BASENAME="$(basename "$FILE")"
  cp "$FILE" "$INBOX/$BASENAME"
  NAMES+=("$BASENAME")
  echo "追加: $BASENAME"
done

cd "$REPO_ROOT"
git add 00_inbox/

echo ""
echo "=== 分析開始 ==="
./scripts/analyze-local.sh "${ANALYZE_OPTS[@]}"
