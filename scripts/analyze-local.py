#!/usr/bin/env python3
"""
analyze-local.py — ローカル環境で inbox ファイルの分析を実行

Claude MAX 認証済みの環境で使用。API Key 不要。

使い方:
  python scripts/analyze-local.py                   # フル分析（Opus）
  python scripts/analyze-local.py --dry-run          # 分類のみ
  python scripts/analyze-local.py --model sonnet     # Sonnet で高速分析
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INBOX = REPO_ROOT / "00_inbox"
PROMPTS = REPO_ROOT / "scripts" / "prompts"

MODEL_MAP = {
    "opus": "claude-opus-4-6",
    "sonnet": "claude-sonnet-4-5-20250929",
}


def find_inbox_files():
    return [f for f in INBOX.rglob("*") if f.is_file() and f.name != ".gitkeep"]


def run_extract():
    """テキスト抽出スクリプトを実行し、出力 JSON のパスを返す。"""
    result = subprocess.run(
        [sys.executable, str(REPO_ROOT / "scripts" / "extract_text.py")],
        cwd=REPO_ROOT,
        check=True,
    )
    # extract_text.py は Windows では ./extracted_texts.json に出力
    for candidate in [REPO_ROOT / "extracted_texts.json", Path("/tmp/extracted_texts.json")]:
        if candidate.exists():
            return candidate
    return None


def build_prompt(prompt_file: Path, extracted_json: Path | None) -> str:
    """プロンプトテンプレート + 抽出データを結合する。"""
    prompt = prompt_file.read_text(encoding="utf-8")
    if extracted_json and extracted_json.exists():
        data = extracted_json.read_text(encoding="utf-8")
        prompt += f"\n\n---\n## 抽出済みテキストデータ\n\n```json\n{data}\n```"
    return prompt


def run_claude(prompt: str, model: str, max_turns: int):
    """Claude Code CLI を実行する。"""
    # プロンプトをテンポラリファイルに書き出し（引数長制限対策）
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False, encoding="utf-8") as f:
        f.write(prompt)
        prompt_path = f.name

    try:
        # Windows ではファイルからプロンプトを読み込む
        cmd = f'claude -p "$(cat {prompt_path})" --model {model} --max-turns {max_turns}'

        # Windows 対応: PowerShell 経由だと $(cat ...) が使えないので stdin pipe を使用
        result = subprocess.run(
            ["claude", "-p", "-", "--model", model, "--max-turns", str(max_turns)],
            input=prompt,
            cwd=REPO_ROOT,
            encoding="utf-8",
        )
        return result.returncode
    finally:
        Path(prompt_path).unlink(missing_ok=True)


def git_commit_push(model: str):
    """変更を commit & push する。"""
    subprocess.run(["git", "add", "-A"], cwd=REPO_ROOT, check=True)

    # 変更があるか確認
    result = subprocess.run(
        ["git", "diff", "--cached", "--quiet"],
        cwd=REPO_ROOT,
    )
    if result.returncode == 0:
        print("変更なし（コミット不要）")
        return

    subprocess.run(
        ["git", "commit", "-m", f"auto: inbox ファイルを分析・分類\n\nモデル: {model}"],
        cwd=REPO_ROOT,
        check=True,
    )
    subprocess.run(["git", "push"], cwd=REPO_ROOT, check=True)
    print("push 完了。")


def main():
    parser = argparse.ArgumentParser(description="inbox ファイルを分析")
    parser.add_argument("--dry-run", action="store_true", help="分類のみ確認")
    parser.add_argument("--model", default="opus", help="モデル（opus/sonnet、デフォルト: opus）")
    args = parser.parse_args()

    model = MODEL_MAP.get(args.model, args.model)
    max_turns = 1 if args.dry_run else 30

    # inbox にファイルがあるか確認
    files = find_inbox_files()
    if not files:
        print("00_inbox/ にファイルがありません。")
        print("使い方: python scripts/inbox.py <ファイル> でファイルを追加してください。")
        sys.exit(0)

    print("=== 対象ファイル ===")
    for f in files:
        print(f"  {f.name}")
    print()

    # Step 1: テキスト抽出
    print("=== Step 1: テキスト抽出 ===")
    extracted_path = run_extract()
    print()

    # Step 2: プロンプト構築
    if args.dry_run:
        prompt_file = PROMPTS / "classify-only.txt"
        print("=== Step 2: 分類のみ（ドライラン） ===")
    else:
        prompt_file = PROMPTS / "analyze-file.txt"
        print("=== Step 2: フル分析 ===")

    prompt = build_prompt(prompt_file, extracted_path)
    print(f"モデル: {model}")
    print(f"最大ターン: {max_turns}")
    print()

    # Step 3: Claude 分析
    print("=== Step 3: Claude 分析実行 ===")
    returncode = run_claude(prompt, model, max_turns)

    # クリーンアップ
    extracted_local = REPO_ROOT / "extracted_texts.json"
    if extracted_local.exists():
        extracted_local.unlink()

    if returncode != 0:
        print(f"\nClaude 分析がエラーで終了しました (code: {returncode})", file=sys.stderr)
        sys.exit(returncode)

    # Step 4: commit & push（ドライランでなければ）
    if not args.dry_run:
        print("\n=== Step 4: コミット & プッシュ ===")
        git_commit_push(model)


if __name__ == "__main__":
    main()
