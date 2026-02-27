lead-developer が以下の手順でコミットを実行します：

1. `git status` でステージング済みの内容を確認
2. ステージング済みファイルがない場合は警告して終了
3. `git diff --staged` で変更差分をレビュー
4. 変更内容を分析し、CLAUDE.mdのコミットメッセージ規約に従ってメッセージを生成：
   ```
   [type]([scope]): [subject]

   [body]

   [footer]
   ```
   - type: 変更種別を判定（feat|fix|docs|style|refactor|test|chore）
   - scope: 影響範囲を特定（optional）
   - subject: 50文字以内で要約
   - body: 必要に応じて詳細説明
   - footer: 関連Issue番号（Closes #123, Fixes #456）
5. `git commit -m "[生成したメッセージ]"` を実行
6. コミット結果を報告

$ARGUMENTS にメッセージのヒントや関連Issue番号があれば考慮する。
