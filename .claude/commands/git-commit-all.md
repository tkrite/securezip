lead-developer が以下の手順で変更のステージングとコミットを一括実行します：

1. `git status` で変更状況を確認
2. 変更がない場合は報告して終了
3. `git diff` で全変更差分をレビュー
4. 変更内容の技術的妥当性を確認
5. 論理的なまとまりでステージングを実行（`git add`）
6. CLAUDE.mdのコミットメッセージ規約に従ってメッセージを生成：
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
7. `git commit -m "[生成したメッセージ]"` を実行
8. 実行結果を報告：
   - コミットハッシュ
   - 変更ファイル数
   - コミットメッセージ

$ARGUMENTS に対象ファイルやメッセージのヒント、関連Issue番号があれば考慮する。
