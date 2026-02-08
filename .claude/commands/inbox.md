00_inbox/ に置かれたファイルを分析・分類・移動し、ナレッジベースを更新してください。

## 手順

1. `00_inbox/` 内のファイルを確認する（.gitkeep 以外）
2. .pptx/.xlsx/.xlsm/.pdf ファイルがあれば `C:\Users\syouta.kawana\AppData\Local\Programs\Python\Python313\python.exe scripts/extract_text.py` を実行してテキストを抽出する
3. 抽出結果（extracted_texts.json）を読み込む
4. CLAUDE.md の仕分けルールに従って分類を判定する
5. `git mv` で正しいフォルダーへ移動する
6. ナレッジベースを更新する（案件カタログ・見積パターン集・案件横断サマリー）
7. 結果サマリーを報告する
8. 一時ファイル（extracted_texts.json）を削除する

## ルール

- すべての出力は日本語で記述すること
- ファイル名だけでなくテキスト内容から分類を判断すること
- 顧客名が不明な場合はユーザーに確認すること
- 分類できない場合は 00_inbox/ に残してユーザーに報告すること
