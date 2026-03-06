# 開発ログ - 2026-03-06

## 📋 基本情報
- **日付**: 2026-03-06
- **開発者**: Claude Code
- **ブランチ**: `master`
- **関連Issue**: -
- **プロジェクトフェーズ**: リリース準備（App Store 提出前最終対応）

## 🎯 本日の開発目標
### 計画タスク
- [x] 仕様書の更新（AppSettings 設計変更・キャンセル秒数上限修正） - 優先度: 高
- [x] Privacy Manifest 作成（App Store 審査要件） - 優先度: 高
- [x] libarchive 静的リンク化（App Store 配布時クラッシュ対策） - 優先度: 高
- [x] コードベース全体レビューと修正（高・中・低優先度 計23件） - 優先度: 高
- [x] App Store 提出手順書作成（担当者向け） - 優先度: 中

### 完了条件
- 全修正後にビルドが通ること
- Privacy Manifest が Xcode ナビゲーターに表示されること
- libarchive 動的依存が app バンドルに含まれないこと

## 📝 実装内容

### 1. 仕様書更新
#### 実装概要
```
要件定義書・技術仕様書を現在の実装に合わせて更新。
AppSettings は Core Data から UserDefaults に変更されており、
仕様書側が古い状態だったため修正。
```
#### 変更ファイル
- `Documents/requirements/requirements_definition.md` - AppSettings エンティティ削除、UserDefaults に更新・キャンセル秒数 30秒→10秒
- `Documents/requirements/technical_specification.md` - 4.2.1〜4.2.4 の AppSettings 関連記述削除、UserDefaults セクション追加・KeychainKey enum 更新

### 2. Privacy Manifest 作成
#### 実装概要
```
Apple が App Store 審査で要求する PrivacyInfo.xcprivacy を新規作成。
使用 API（UserDefaults・File Timestamp）とその理由コードを宣言。
Xcode 16 の PBXFileSystemSynchronizedRootGroup により、
project.pbxproj を編集せずにファイル配置のみで自動認識。
```
#### 変更ファイル
- `SecureZip/SecureZip/PrivacyInfo.xcprivacy`（新規作成）
  - NSPrivacyTracking: false
  - NSPrivacyAccessedAPICategoryUserDefaults: CA92.1
  - NSPrivacyAccessedAPICategoryFileTimestamp: 0A2A.1

### 3. libarchive 静的リンク化
#### 実装概要
```
Homebrew の libarchive は動的リンク（.dylib）のため、
App Store に提出した場合にユーザー環境で Homebrew が未インストールだとクラッシュする。
静的リンク（.a ファイル）に切り替えることで依存を解消。
```
#### 技術的詳細
```
OTHER_LDFLAGS を以下に変更（Debug/Release 両方）:
/opt/homebrew/opt/libarchive/lib/libarchive.a
/opt/homebrew/opt/xz/lib/liblzma.a
/opt/homebrew/opt/zstd/lib/libzstd.a
/opt/homebrew/opt/lz4/lib/liblz4.a
/opt/homebrew/opt/libb2/lib/libb2.a
-lbz2 -lz -liconv
```
#### 発生した問題
- 最初の変更後に `Undefined symbol: _BZ2_bzCompress` 等のエラー
- libarchive が依存する libbz2 / libz / libiconv の指定が不足していたため
- `-lbz2 -lz -liconv` を追加して解決

#### 変更ファイル
- `SecureZip/SecureZip.xcodeproj/project.pbxproj` - OTHER_LDFLAGS 更新

### 4. コードベース全体レビュー・修正（23件）

#### 高優先度（6件）
| # | 対象 | 修正内容 |
|---|------|---------|
| H-1 | DecompressViewModel | `@MainActor` をクラスに追加、progress 更新を `Task { @MainActor [weak self] in }` でラップ |
| H-2 | CompressViewModel, DecompressViewModel, SendViewModel | `startAccessingSecurityScopedResource()` / `defer stopAccessing()` 追加 |
| H-3 | LibArchiveWrapper | ZIP Slip 対策（パスサニタイズ・destination 配下チェック） |
| H-4 | GmailService | `resumed` フラグで continuation 二重 resume 防止 |
| H-5 | SendViewModel | CancellationError 時の状態リセット追加 (`isCountingDown = false`, `countdown = 0`) |
| H-6 | GmailAPIClient | デッドコード削除、buildMIMEMessage を async throws に変更、添付ファイル読込を Task.detached で非同期化 |

#### 中優先度（9件）
| # | 対象 | 修正内容 |
|---|------|---------|
| M-1 | AutoDeleteService | `deinit` 削除、UserDefaults キーを UDKey 定数に統一 |
| M-2 | HistoryService | NSEntityDescription.insertNewObject 推奨パターンに変更 |
| M-3 | SendViewModel | UserDefaults キーを `SettingsViewModel.UDKey` 定数に統一 |
| M-4 | PasswordGeneratorSheet | onAppear で UserDefaults から設定値を引き継ぐように修正 |
| M-5 | LibArchiveWrapper | TAR 圧縮・解凍に時間ベース進捗シミュレーション追加 |
| M-6 | GmailAPIClient | sendEndpoint を static let からインスタンスプロパティに変更（テスト容易性向上） |
| M-7 | CompressViewModel | 圧縮完了後 `password = ""` でパスワードクリア |
| M-8 | HistoryView | `List { ForEach(...).onDelete { ... } }` でスワイプ削除 UI 追加 |
| M-9 | GmailService | passwordEmailDelayNanoseconds 定数化 |

#### 低優先度（8件）
| # | 対象 | 修正内容 |
|---|------|---------|
| L-1 | CryptoService | generateKeyPair() を CryptoKitWrapper に委譲 |
| L-2 | KeychainService | OAuthトークン保管コメント修正 |
| L-3 | String+Extensions | IDN 非対応の制限コメント追記 |
| L-4 | CompressionService + Localizable.strings | errorDescription を NSLocalizedString に変更・エラーキー10件追加（ja/en） |
| L-5 | PasswordService | acceptLimit の型を Int に統一、比較を `Int(byte) < acceptLimit` に変更 |
| L-6 | CompressView | openSavePanel() の冗長な `@MainActor` 削除 |
| L-7 | DecompressView | 「ファイルが選択されていません」の多言語対応（`if let` 分岐に変更） |
| L-8 | GmailAPIClient | retryStatus の冗長な分岐を削除 |

### 5. App Store 提出手順書整理（担当者向け）
#### 実装概要
```
担当者（App Store Connect アカウント保有者）向けに、
以下3ステップの手順・入力内容を整理・説明。
1. Google OAuth 本番審査申請（制限付きスコープ審査）
2. EAR（暗号化輸出規制）申告（ERN 免除）
3. TestFlight 内部テスト配布・外部テスト招待
```

## 🧪 テスト実施

### 動作確認
| 確認項目 | 結果 | 備考 |
|---------|------|------|
| 静的リンク後ビルド | ✅ | Undefined symbol エラー解消 |
| Privacy Manifest Xcode 表示 | ✅ | ナビゲーターに PrivacyInfo 確認 |
| DecompressViewModel @MainActor 警告 | ✅ | progress クロージャ修正で解消 |
| DecompressView 多言語対応 | ✅ | プレースホルダーが `??` 演算子から `if let` 分岐に変更 |

## 🐛 発生した問題と解決

### 問題1: libarchive 静的リンク後 Undefined symbol
**症状**:
```
Undefined symbol: _BZ2_bzCompress
Undefined symbol: _deflate
Undefined symbol: _iconv
```
**原因**: libarchive.a が内部で libbz2 / libz / libiconv に依存しているが、それらの指定が抜けていた

**解決方法**:
```
OTHER_LDFLAGS の末尾に -lbz2 -lz -liconv を追加
```

### 問題2: DecompressViewModel @MainActor 追加後の Sendable 警告
**症状**:
```
Main actor-isolated property 'progress' can not be mutated from a Sendable closure
```
**原因**: progress クロージャが `@Sendable` コンテキストで直接 @MainActor プロパティを更新しようとしていた

**解決方法**:
```swift
progress: { [weak self] p in
    Task { @MainActor [weak self] in
        self?.progress = p
    }
}
```

### 問題3: DecompressView 多言語対応漏れ
**症状**: `Text(vm.selectedFile?.lastPathComponent ?? "ファイルが選択されていません")` が LocalizedStringKey として扱われない

**原因**: `??` 演算子で String 型を生成すると LocalizedStringKey 扱いにならず、ja.lproj の翻訳が適用されない

**解決方法**:
```swift
if let filename = vm.selectedFile?.lastPathComponent {
    Text(filename)
} else {
    Text("ファイルが選択されていません")
}
```

## 💡 技術的発見・学習

### 新しく学んだこと
- Xcode 16 の PBXFileSystemSynchronizedRootGroup：ファイルを配置するだけで project.pbxproj への手動追加が不要
- Privacy Manifest：NSPrivacyAccessedAPITypes の reason code は Apple 定義の固定値（CA92.1 / 0A2A.1）
- `Text("文字列")` と `Text(stringVariable)` では LocalizedStringKey 解釈が異なる

### ベストプラクティス
- Security-scoped URL は `startAccessingSecurityScopedResource()` / `defer stop` のペアで必ず管理
- withCheckedThrowingContinuation は `resumed` フラグで二重 resume を防止
- UserDefaults キーは 1ヶ所（UDKey enum）で一元管理し、文字列リテラルの重複を排除

## 📊 進捗状況

### 本日の成果
- ✅ 完了: 仕様書更新
- ✅ 完了: Privacy Manifest 作成
- ✅ 完了: libarchive 静的リンク化
- ✅ 完了: コードレビュー修正 23件
- ✅ 完了: App Store 提出手順書整理
- 📋 未着手（担当者対応待ち）: Google OAuth 本番審査申請 / EAR 申告 / TestFlight 配布

### 全体進捗
```
機能実装:     [██████████] 100%
コード品質:   [█████████░]  95%
テスト:       [████████░░]  80%
App Store 提出: [██░░░░░░░░] 20%（担当者作業待ち）
```

## 🔄 コミット履歴

```
# 本セッションの主要変更（未コミット）
- docs: 要件定義書・技術仕様書をAppSettings→UserDefaults、秒数上限修正
- feat: Privacy Manifest (PrivacyInfo.xcprivacy) 追加
- chore(xcode): libarchive を静的リンクに変更
- fix(decompress): @MainActor 追加・progress Sendable 警告解消・Security-scoped URL 対応
- fix(compress): Security-scoped URL 対応・圧縮後パスワードクリア
- fix(send): Security-scoped URL 対応・UDKey 統一・CancellationError 状態リセット
- fix(libarchive): ZIP Slip 対策・TAR 進捗シミュレーション追加
- fix(gmail): continuation 二重 resume 防止・定数化・async throws 変更
- fix(services): AutoDeleteService deinit 削除・HistoryService 推奨パターン・PasswordGeneratorSheet 設定引継ぎ
- fix(history): スワイプ削除 UI 追加
- fix(errors): errorDescription NSLocalizedString 化・ja/en 翻訳追加
- fix(password): acceptLimit 型統一
- fix(decompress-view): 多言語対応 if let 分岐に変更
```

## 🔮 次回の予定

### 担当者対応待ちタスク
1. Google OAuth 本番審査申請（`gmail.send` スコープ・制限スコープ審査）
2. EAR 申告（ERN 免除・`ITSAppUsesNonExemptEncryption = YES`）
3. TestFlight 内部テスト配布 → フィードバック収集 → 外部テスト

### 懸念事項
- Google OAuth 審査では「ホームページ URL」が任意項目だが、審査中に提出を求められる可能性あり
  → GitHub Pages 等で簡易ページを用意しておくことを推奨
- TestFlight 外部テストは最大 10,000人招待可能だが、審査（通常 1〜2日）が必要

## 📌 メモ・備考

### Google OAuth ホームページ URL について
- 必須項目ではない（任意）
- ただし `gmail.send` 等の制限スコープ審査では審査チームから求められる場合がある
- プライバシーポリシー URL は**必須**（審査で必ず要求される）
- 対応策: GitHub Pages / Notion 等で最低限のページを用意し、プライバシーポリシーを掲載

## 📈 メトリクス

| 指標 | 値 |
|------|-----|
| 修正件数 | 23件 |
| 変更ファイル数 | 約20ファイル |
| 新規ファイル | 2（PrivacyInfo.xcprivacy, en.lproj/Localizable.strings） |
| 削除ファイル | 1（Resources/Localizable.strings → lproj 分割） |
| 生産性 | 高 |

## 🏷️ タグ
`#development` `#appstore-prep` `#code-review` `#swift` `#macos` `#security` `#2026-03-06`

---
*作成: 2026-03-06 JST*
*最終更新: 2026-03-06 JST*
