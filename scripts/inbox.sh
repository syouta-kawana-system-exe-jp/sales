#!/bin/bash
# inbox.sh — ファイルを 00_inbox/ に追加して push するヘルパースクリプト
#
# 使い方:
#   ./scripts/inbox.sh ファイル1.pptx [ファイル2.xlsx ファイル3.pdf ...]
#   ./scripts/inbox.sh ~/Downloads/*.pptx

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$REPO_ROOT/00_inbox"

if [ $# -eq 0 ]; then
  echo "使い方: ./scripts/inbox.sh <ファイル> [ファイル2 ...]"
  echo "例:     ./scripts/inbox.sh ~/Downloads/IRIS提案書.pptx"
  exit 1
fi

# ファイルを 00_inbox/ にコピー
NAMES=()
for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    echo "エラー: $FILE が見つかりません" >&2
    exit 1
  fi
  BASENAME="$(basename "$FILE")"
  cp "$FILE" "$INBOX/$BASENAME"
  NAMES+=("$BASENAME")
  echo "追加: $BASENAME"
done

# git add, commit, push
cd "$REPO_ROOT"
git add 00_inbox/
git commit -m "add: ${NAMES[*]}"
git push

echo ""
echo "完了: ${#NAMES[@]} ファイルを push しました。Actions タブで分析結果を確認してください。"
