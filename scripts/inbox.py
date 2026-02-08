#!/usr/bin/env python3
"""
inbox.py — ファイル追加 → 分析 → コミット → push を1コマンドで実行

使い方:
  python scripts/inbox.py ファイル1.pptx [ファイル2.xlsx ...]
  python scripts/inbox.py --dry-run ファイル.pptx
  python scripts/inbox.py --model sonnet ファイル.pptx
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INBOX = REPO_ROOT / "00_inbox"


def main():
    parser = argparse.ArgumentParser(description="ファイルを inbox に追加して分析を実行")
    parser.add_argument("files", nargs="+", help="追加するファイル")
    parser.add_argument("--dry-run", action="store_true", help="分類のみ確認（ファイル移動なし）")
    parser.add_argument("--model", default=None, help="モデル指定（sonnet / opus）")
    args = parser.parse_args()

    # ファイルを 00_inbox/ にコピー
    names = []
    for filepath in args.files:
        src = Path(filepath)
        if not src.exists():
            print(f"エラー: {src} が見つかりません", file=sys.stderr)
            sys.exit(1)
        dest = INBOX / src.name
        shutil.copy2(str(src), str(dest))
        names.append(src.name)
        print(f"追加: {src.name}")

    # git add
    subprocess.run(["git", "add", "00_inbox/"], cwd=REPO_ROOT, check=True)

    # analyze-local.py に委譲
    print("\n=== 分析開始 ===")
    cmd = [sys.executable, str(REPO_ROOT / "scripts" / "analyze-local.py")]
    if args.dry_run:
        cmd.append("--dry-run")
    if args.model:
        cmd.extend(["--model", args.model])
    result = subprocess.run(cmd, cwd=REPO_ROOT)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
