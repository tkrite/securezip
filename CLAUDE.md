# Claude Code プロジェクト設定

## 基本設定

- **タイムゾーン**: UTC+9 (JST)
- **応答言語**: 日本語 (JP)
- **プロジェクトルート**: ./
- **開発手法**: Git Worktree マルチエージェント開発

## プロジェクト構造

```
Project/                            # 親ディレクトリ
├── main-project/                   # メインプロジェクト（現在地: ./）
│   ├── .claude/                    # Claude Code設定
│   │   ├── agents/                 # エージェント定義
│   │   ├── commands/               # カスタムコマンド
│   │   └── templates/              # コマンド用テンプレート
│   ├── Documents/                  # プロジェクト文書
│   │   ├── analysis/               # 分析結果
│   │   ├── logs/                   # ログ情報
│   │   │   ├── amendment/          # 修正ログ
│   │   │   └── development/        # 開発ログ
│   │   ├── notes/                  # 開発用ノート
│   │   │   ├── daily/              # デイリーノート
│   │   │   ├── quick/              # クイックノート
|   |   |   └── tips/               # ティップス
│   │   ├── project_structure/      # プロジェクト構成
│   │   ├── plan/                   # plan modeで作成したドキュメントのアーカイブ
│   │   ├── requirements/           # 要件定義
│   │   │   ├── requirements_definition.md
│   │   │   └── technical_specification.md
│   │   ├── test_results/           # テスト結果
|   |   └── tickets/                 # 開発用チケット
│   ├── .gitignore                  # ignoreファイル
│   ├── CLAUDE.md                   # この設定ファイル
|   └── README.md                   # アプリ全体の利用法などのREADMEファイル
├── project-feature-*/              # Worktree（機能開発用）
├── project-fix-*/                  # Worktree（バグ修正用）
├── project-exp-*/                  # Worktree（実験的開発用）
└──references/                      # DocDriven開発用の参照情報（ユーザー用の為、Claudeによる参照不要）
└── samples/                        # 共有サンプルデータ
    ├── code/                       # コードサンプル
    ├── image/                      # 画像サンプル
    ├── markdown/                   # ドキュメントサンプル
    └── pdf/                        # PDFサンプル
```

## 重要パス定義

### プロジェクト内リソース

#### 要件・仕様

- **要件定義書**: `./Documents/requirements/requirements_definition.md`
- **技術仕様書**: `./Documents/requirements/technical_specification.md`

#### プロジェクト文書管理

- **プロジェクト仕様書**: `./Documents/project_structure/`

#### ログ・記録

- **開発ログ**: `./Documents/logs/development/`
- **修正ログ**: `./Documents/logs/amendment/`
- **デイリーノート**: `./Documents/notes/daily/`
- **クイックノート**: `./Documents/notes/quick/`
- **ティップス**: `./Documents/notes/tips/`

#### 成果物

- **テスト結果**: `./Documents/test_results/`
- **分析レポート**: `./Documents/analysis/`

### 共有リソース

- **サンプルデータ**: `../samples/`
  - コードサンプル: `../samples/code/`
  - 画像リソース: `../samples/image/`
  - ドキュメント例: `../samples/markdown/`
  - PDF 資料: `../samples/pdf/`

### Claude Code 設定

- **エージェント定義**: `./.claude/agents/`
- **カスタムコマンド**: `./.claude/commands/`
- **テンプレート**: `./.claude/templates/`

### 開発用チケット

- **チケット**: `./Documents/tickets/`

## Git Worktree 運用ルール

### Worktree 作成ポリシー

- Worktree 作成はユーザーの明示的な指示に基づいてのみ実行

### Worktree 作成規則

```bash
# 機能開発
git worktree add ../project-feature-[機能名] -b feature/[機能名]

# バグ修正
git worktree add ../project-fix-[issue番号] -b fix/issue-[番号]

# 実験的開発
git worktree add ../project-exp-[実験名] -b experimental/[実験名]
```

### ブランチ戦略

- **main**: 安定版（直接コミット禁止）
- **feature/\***: 新機能開発
- **fix/\***: バグ修正
- **experimental/\***: 実験的実装

### ブランチ命名規則

- 小文字、ハイフン区切り、英語で統一
- feature/[機能名] または feature/[issue 番号]-[機能名]
- fix/issue-[番号] または fix/[簡潔な説明]
- experimental/[実験内容]

## プロジェクト文書管理

### 文書の役割

- **要件定義書・技術仕様書**: 初期要求の記録（固定・変更なし）
- **PROJECT_STRUCTURE.md**: 現在の実装状態（継続的更新）

### PROJECT_STRUCTURE 更新ルール

- **更新タイミング**: 設計変更、機能追加、フェーズ完了時
- **保存先**: `./Documents/project_structure/YYYY-MM-DD_vX.Y_[description].md`
- **閲覧用（シンボリックリンク）**: `./Documents/PROJECT_STRUCTURE.md`
- **テンプレート**: `.claude/templates/project-structure-template.md`

## チケット管理

### チケットの役割

- **差し込み開発**: 不足を感じた部分に関する requirements 記載以外の追加開発
- **バグ修正**: 人による検証に基づいたバグ修正依頼

### チケット名称

- **差し込み開発**: ticket-dev-XXX.md
- **バグ修正**: ticket-fix-XXX.md

## マルチエージェント開発

### エージェント役割

1. **code-reviewer** (`./.claude/agents/code-reviewer.md`)
   - コード品質チェック
   - ベストプラクティス確認
   - セキュリティレビュー

2. **data-scientist** (`./.claude/agents/data-scientist.md`)
   - データ分析
   - アルゴリズム最適化
   - 統計的検証

3. **debugger** (`./.claude/agents/debugger.md`)
   - エラー解析
   - パフォーマンス問題調査
   - 修正提案

4. **document-reviewer** (`./.claude/agents/document-reviewer.md`)
   - ドキュメントレビュー
   - ベストプラクティス確認
   - 情報抽出

5. **document-writer** (`./.claude/agents/document-writer.md`)
   - 文書制作
   - 文書整合性管理
   - テンプレート適用

6. **lead-developer** (`./.claude/agents/lead-developer.md`)
   - 技術的意思決定と開発方針策定
   - 開発ログ・修正ログの技術レビュー
   - 実装内容と要件・設計の整合性確認

7. **project-manager** (`./.claude/agents/project-manager.md`)
   - プロジェクト全体把握
   - プロジェクト構造分析
   - プロジェクト履歴管理

8. **test-engineer** (`./.claude/agents/test-engineer.md`)
   - テスト実行
   - 品質保証
   - テスト結果レポート

### カスタムコマンド仕様

1. 要件確認 → 実装
2. debugger: テスト・問題特定
3. lead-developer: レビュー実施
4. data-scientist: 最適化（必要時）
5. マージ準備

## 開発規約

### ファイル命名規則

- **ソースファイル**: `kebab-case.ext`
- **クラスファイル**: `PascalCase.ext`
- **テストファイル**: `*.test.ext` または `*.spec.ext`
- **設定ファイル**: `*.config.ext`

#### ドキュメント

- **プロジェクト構造**: `YYYY-MM-DD_vX.Y_[description].md`
- **開発ログ**: `YYYY-MM-DD_dev-[topic].md`
- **修正ログ**: `YYYY-MM-DD_fix-[issue].md`
- **デイリーノート**: `YYYY-MM-DD_daily.md`
- **クイックノート**: `YYYY-MM-DD_HHmm_[topic].md`
- **分析レポート**: `YYYY-MM-DD_analysis-[topic].md`
- **テスト結果**: `YYYY-MM-DD_test-[type].md`

### コミットメッセージ規約

```
[type]([scope]): [subject]

[body]

[footer]
```

- **type**: feat|fix|docs|style|refactor|test|chore
- **scope**: 影響範囲（optional）
- **subject**: 50 文字以内の要約
- **footer**: Issue 番号（Closes #123, Fixes #456）

### コーディング規約

- **変数名**: camelCase
- **定数**: UPPER_SNAKE_CASE
- **関数**: camelCase（動詞で開始）
- **クラス**: PascalCase
- **プライベート**: アンダースコア接頭辞（\_privateMethod）

## サンプルデータ利用ガイド

### 参照方法

- サンプルは読み取り専用として扱う
- 修正が必要な場合はプロジェクト内にコピー
- パス: `../samples/[category]/[file]`

### 利用例

```markdown
# コードサンプル参照

参照: ../samples/code/python/api_example.py

# テストデータ利用

データ: ../samples/data/test_users.json
```

## 禁止事項

- ❌ main ブランチへの直接プッシュ
- ❌ レビューなしのマージ
- ❌ テストなしの本番デプロイ
- ❌ サンプルディレクトリ（../samples/）への直接変更
- ❌ CLAUDE.md の無断変更
