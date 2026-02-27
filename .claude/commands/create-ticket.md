# チケット作成コマンド

plan の内容に基づいて、lead-developer と document-writer エージェントが協力してチケットを作成します。

## 実行フロー

### 1. 情報収集（lead-developer）

まず lead-developer として以下を確認します：

1. **plan の確認**
   - `./Documents/plan/` 内のアーカイブされた計画を確認
   - 開発対象の機能・修正内容を特定

2. **要件定義の確認**
   - `./Documents/requirements/requirements_definition.md` を参照
   - `./Documents/requirements/technical_specification.md` を参照

3. **現在のプロジェクト構造の確認**
   - `./Documents/project_structure/` 内の最新ファイルを確認
   - 影響範囲を特定

### 2. チケット内容の検討（lead-developer）

lead-developer として以下を決定します：

1. **チケットの種別判定**
   - `ticket-dev-XXX.md`: 新機能開発・差し込み開発
   - `ticket-fix-XXX.md`: バグ修正

2. **機能単位での分割検討**
   - 1チケット = 1機能（または1修正）の原則
   - 依存関係がある場合は実行順序を明記
   - 見積もり作業時間が4時間を超える場合は分割を検討

3. **チケット内容の策定**
   - 目的・背景
   - 完了条件（受入基準）
   - 技術的な実装方針
   - 影響範囲・リスク
   - 優先度

### 3. チケット作成（document-writer）

document-writer として以下を実行します：

1. **テンプレートの選択**
   - 開発チケット: `.claude/templates/ticket-dev-template.md`
   - 修正チケット: `.claude/templates/ticket-fix-template.md`

2. **チケット番号の採番**
   ```bash
   # 既存チケットの確認
   ls ./Documents/tickets/
   
   # 次の番号を決定（例: 既存が001, 002なら003）
   ```

3. **ファイル作成**
   - 保存先: `./Documents/tickets/`
   - 命名規則:
     - 開発: `ticket-dev-XXX.md`（XXX: 3桁の連番）
     - 修正: `ticket-fix-XXX.md`

4. **内容記入**
   - lead-developer が策定した内容をテンプレートに記入
   - 日付、ステータス、関連情報を正確に記録

### 4. 確認・完了

1. **作成したチケットの表示**
   - チケット内容をユーザーに提示
   - 修正が必要な箇所を確認

2. **ユーザーレビュー待ち**
   - ステータスは「Draft」のまま
   - ユーザーの承認後に「Open」へ変更

## 出力例

```
📋 チケット作成完了

作成チケット: ./Documents/tickets/ticket-dev-003.md
種別: 開発チケット
タイトル: ユーザー認証機能の実装
優先度: 高
見積もり: 3時間

---
チケット内容のレビューをお願いします。
修正が必要な場合はお知らせください。
承認後、開発を開始できます。
```

## 複数チケット作成時

plan に複数の機能が含まれる場合：

1. 各機能を独立したチケットとして作成
2. 依存関係がある場合は `関連チケット` セクションに記載
3. 実行順序の推奨を提示

## 注意事項

- チケットは必ず機能単位で分割する
- 1つのチケットで複数の無関係な機能を扱わない
- ユーザーの承認なしにステータスを「Open」にしない
- 不明点がある場合はユーザーに確認してからチケットを作成
