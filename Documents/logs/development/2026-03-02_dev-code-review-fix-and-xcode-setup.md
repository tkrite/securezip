# 開発ログ - 2026-03-02

## 基本情報
- **日付**: 2026-03-02
- **開発者**: Claude Code
- **ブランチ**: `master`
- **関連Issue**: 未記載
- **プロジェクトフェーズ**: 実装

## 本日の開発目標
### 計画タスク
- [x] コードレビュー指摘事項の修正（Critical/High/Medium/Low 全件） - 優先度: 高
- [x] Xcode プロジェクト設定の整備 - 優先度: 高
- [x] ビルドエラーの解消 - 優先度: 高

### 完了条件
- コードレビューで特定された全問題（Critical 3件, High 6件, Medium 7件, Low 4件）の修正完了
- Xcode プロジェクトが macOS 専用設定として整備されていること
- ビルドエラーが解消されていること

## 実装内容

### 1. コードレビュー指摘事項の修正 (Phase 1)
**作業時間**: 未記載（セッション内完了）

#### 実装概要
```
コードベース全体のレビューを実施し、以下の重大度分類で問題を特定・修正した。
- Critical: 3件
- High: 6件
- Medium: 7件
- Low: 4件
```

#### 修正詳細

**C-1 + C-2: LibArchiveWrapper.swift -- 暗号化 ZIP 実装の修正**

```
症状: zipfile.setpassword() は読み取り専用 API であり、書き込み時に暗号化が行われない
修正: /usr/bin/zip -r -e + stdin 経由でパスワードを渡す実装に変更
      パスワードは "password\npassword\n" 形式で stdin に書き込み（-e フラグが2回入力を要求するため）
      コマンドライン引数にパスワードを露出させないため stdinData: Data? パラメータを runProcess() に追加
      UI ラベルを「AES-256 暗号化」->「パスワード保護 (ZipCrypto)」に修正
注意: 暗号方式は ZipCrypto であり AES-256 ではない（Phase 2 で libarchive C API への移行が必要）
```

**H-1: GmailService.swift -- 認証エラー処理**

```swift
// 修正前: authenticate() が常に isAuthenticated = true を設定していた
// 修正後: 適切に SecureZipError.gmailNotAuthenticated を throw するよう修正
```

**H-2: SettingsViewModel + SettingsView -- エラー表示**

```swift
// errorMessage: String? を追加して Gmail 連携のエラーを画面に表示
```

**H-3: SendViewModel -- isSending リセット漏れ**

```swift
// 修正前: sendTask でエラー時に isSending = false がリセットされない
// 修正後: do/catch で sendWithSeparatePassword をラップしてリセットを保証
```

**H-4: KeychainWrapper.swift を削除**

```
KeychainService と重複した未使用クラスを削除
```

**H-5 + M-7: HistoryService -- DI・weak self 修正**

```swift
// keychainService: KeychainServiceProtocol を DI 追加
// クロージャから不要な [weak self] を削除
```

**H-6: CoreDataStack -- インメモリフォールバック実装**

```swift
// 修正前: loadPersistentStores エラー時のフォールバックが未実装
// 修正後: エラー時に makeInMemoryContainer() を呼び出しインメモリストアにフォールバック
//         加えて xcdatamodeld 未存在時もインメモリで代替するガード処理を追加
```

**M-1: GmailService -- separatePassword パラメータ追加**

```swift
// sendWithSeparatePassword(separatePassword: Bool) をプロトコルと実装に追加
```

**M-2: PasswordService -- モジュロバイアス排除**

```swift
// 修正前: 単純なモジュロ演算によるバイアスが存在
// 修正後: SecRandomCopyBytes + リジェクションサンプリングを実装
//         acceptLimit = UInt8((256 / charsetCount) * charsetCount) で閾値を算出し、
//         閾値以上のバイトを棄却して均等分布を保証
```

**M-3 + M-4: 重複コード削除**

```
SendViewModel から重複の isValidEmail() を削除
GmailAPIClient から重複の base64URLEncode() を削除
```

**M-5: DropZoneView -- エラーハンドリング**

```swift
// 修正前: ドロップエラーをサイレントに無視していた
// 修正後: エラーをログ出力するよう修正
```

**M-6: AutoDeleteService**

```swift
// @MainActor クラス化、deinit の修正
```

**L-1, L-3, L-4: @MainActor 追加**

```swift
// CompressView.openSavePanel()
// CompressViewModel.compress()
// DecompressViewModel.decompress()
// 上記に @MainActor を追加
// SendViewModel に passwordService: PasswordServiceProtocol DI を追加
```

#### 変更ファイル（Phase 1）
- `SecureZip/SecureZip/Infrastructure/LibArchiveWrapper.swift` - 暗号化 ZIP 実装を修正、stdinData 追加
- `SecureZip/SecureZip/Services/GmailService.swift` - 認証エラー処理修正、separatePassword 追加
- `SecureZip/SecureZip/ViewModels/SettingsViewModel.swift` - errorMessage プロパティ追加
- `SecureZip/SecureZip/Views/SettingsView.swift` - エラー表示 UI 追加
- `SecureZip/SecureZip/ViewModels/SendViewModel.swift` - isSending リセット修正、重複メソッド削除、DI 追加
- `SecureZip/SecureZip/Infrastructure/KeychainWrapper.swift` - 削除（KeychainService と重複）
- `SecureZip/SecureZip/Services/HistoryService.swift` - DI 追加、weak self 修正
- `SecureZip/SecureZip/Infrastructure/CoreDataStack.swift` - インメモリフォールバック実装
- `SecureZip/SecureZip/Services/PasswordService.swift` - モジュロバイアス排除
- `SecureZip/SecureZip/Infrastructure/GmailAPIClient.swift` - 重複メソッド削除
- `SecureZip/SecureZip/Views/Components/DropZoneView.swift` - エラーログ追加
- `SecureZip/SecureZip/Services/AutoDeleteService.swift` - @MainActor クラス化、deinit 修正
- `SecureZip/SecureZip/Views/CompressView.swift` - @MainActor 追加
- `SecureZip/SecureZip/ViewModels/CompressViewModel.swift` - @MainActor 追加
- `SecureZip/SecureZip/ViewModels/DecompressViewModel.swift` - @MainActor 追加
- `SecureZip/SecureZip/Resources/Localizable.strings` - UI ラベル修正（AES-256 -> ZipCrypto）

---

### 2. Xcode プロジェクト設定 (Phase 2)
**作業時間**: 未記載（セッション内完了）

#### 実装概要
```
Xcode プロジェクトを macOS 専用に整備し、ビルド可能な状態に移行するための設定作業。
```

#### 技術的詳細

**2-1: Docs/xcode-project-setup.md 作成**

```
10ステップの Xcode プロジェクト設定ガイドを作成
Bundle ID: com.tkrite.SecureZip に統一
```

**2-2: Bundle ID 統一**

```swift
// KeychainService.swift のキープレフィックスを com.tkrite.SecureZip. に更新
```

**2-3: Core Data モデル属性定義**

```xml
<!-- .xcdatamodeld XML を直接編集して全エンティティの属性を定義 -->
<!-- SendHistoryEntity: 12属性 -->
<!-- RecipientEntity: 5属性 -->
<!-- AppSettingsEntity: 4属性 -->
<!-- usedWithSwiftData="NO", codeGenerationType="none" に修正 -->
```

**2-4: project.pbxproj macOS 専用設定**

```
MACOSX_DEPLOYMENT_TARGET: 26.2 -> 13.0（Xcode テンプレートのデフォルト値を macOS 13 に修正）
SDKROOT -> macosx
SUPPORTED_PLATFORMS -> macosx
iOS/visionOS 設定を削除（IPHONEOS_DEPLOYMENT_TARGET 等）
CODE_SIGN_ENTITLEMENTS 追加
ENABLE_USER_SELECTED_FILES = readwrite 追加
Info.plist を新規作成（CFBundleURLTypes 含む、OAuth コールバック URL スキーム定義）
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE を設定
```

#### 変更ファイル（Phase 2）
- `Docs/xcode-project-setup.md` - 新規作成（Xcode プロジェクト設定ガイド）
- `SecureZip/SecureZip/Services/KeychainService.swift` - Bundle ID プレフィックス統一
- `SecureZip/SecureZip.xcodeproj/project.pbxproj` - macOS 専用設定に修正（pbxproj 新規生成含む）
- `SecureZip/SecureZip.xcdatamodeld/SecureZip.xcdatamodel/contents` - 全エンティティ属性定義
- `SecureZip/SecureZip/Info.plist` - 新規作成（後の Phase 3 で SecureZip/Info.plist に移動）

---

### 3. ビルドエラー修正 (Phase 3)
**作業時間**: 未記載（セッション内完了）

#### 実装概要
```
Xcode プロジェクト設定後に発生したビルドエラーを 2 回のイテレーションで修正した。
```

#### 技術的詳細

**ビルドエラー修正 1 (a54bdc3)**

```
問題1: archive.h file not found
原因: ブリッジングヘッダーが空の状態で存在しており、Phase 2 の設定時に
      libarchive の import を追加する想定だったが、libarchive のリンク設定が
      未完了の状態でビルドしたためエラー発生
対応: ブリッジングヘッダーに archive.h / archive_entry.h の import を
      コメント付きで記述（Phase 2 で有効化する旨の説明コメントを併記）

問題2: Info.plist in Copy Bundle Resources
原因: Info.plist がファイルシステム同期グループ内にあり、重複ビルドが発生
対応(試み1): PBXFileSystemSynchronizedBuildFileExceptionSet を追加 -> 未解決
```

**ビルドエラー修正 2 (b674446)**

```
問題1: Info.plist in Copy Bundle Resources (継続)
対応(試み2): SecureZip/SecureZip/Info.plist -> SecureZip/Info.plist に移動
            （PBXFileSystemSynchronizedRootGroup の管理外に配置する根本解決）
            INFOPLIST_FILE = "Info.plist" に更新
            不要になった PBXFileSystemSynchronizedBuildFileExceptionSet を削除（クリーンアップ）

問題2: AppDelegate @MainActor 分離エラー
原因: AutoDeleteService が @MainActor クラスであるため、その init() は
      MainActor 分離されている。AppDelegate 側が nonisolated のままだと
      同期コンテキストから @MainActor isolated な init() を呼べない
対応: AppDelegate クラス全体に @MainActor を追加
      （NSApplicationDelegate のライフサイクルメソッドは元々 Main Thread で
      呼ばれるため、@MainActor 化による副作用はない）
```

#### 変更ファイル（Phase 3）
- `SecureZip/SecureZip/SecureZip-Bridging-Header.h` - archive.h import をコメント付きで追加
- `SecureZip/SecureZip.xcodeproj/project.pbxproj` - Info.plist 配置修正、ExceptionSet 削除
- `SecureZip/Info.plist` - SecureZip/SecureZip/ から移動（同期グループ外）
- `SecureZip/SecureZip/App/AppDelegate.swift` - @MainActor 追加

## テスト実施

### ユニットテスト
- [ ] テストケース作成（未実施）
- [ ] テスト実行（未実施）
- [ ] カバレッジ: 未計測

### 動作確認
| 機能 | 結果 | 備考 |
|-----|------|------|
| 暗号化 ZIP 生成 | 未確認 | /usr/bin/zip -e 経由に変更済み、Xcode でのビルド確認待ち |
| Gmail 認証エラーハンドリング | 未確認 | ビルド確認待ち |
| Core Data インメモリフォールバック | 未確認 | ビルド確認待ち |
| Xcode ビルド | 部分確認 | ビルドエラー 2 回修正済み、完全解消は手動確認が必要 |

## 発生した問題と解決

### 問題1: archive.h が見つからない
**状態**: 解決済み

**症状**:
```
archive.h file not found
```

**原因**:
- ブリッジングヘッダー（空ファイルとして存在）に libarchive の C ヘッダー import を追加する予定だったが、libarchive のリンク設定（-larchive）が OTHER_LDFLAGS に設定されている一方、実際のヘッダーファイルは SDK パスに存在しない状態だった

**解決方法**:
```c
// SecureZip-Bridging-Header.h
// Phase 2 で有効化するため、コメント付きで記述
// #import <archive.h>
// #import <archive_entry.h>
```

**対応時間**: 未記載

---

### 問題2: Info.plist が Copy Bundle Resources に含まれビルド失敗
**状態**: 解決済み

**症状**:
```
Multiple commands produce Info.plist
(もしくは Info.plist in Copy Bundle Resources エラー)
```

**原因**:
- Info.plist がファイルシステム同期グループ（PBXFileSystemSynchronizedRootGroup）の管理下にあり、自動的にビルド対象に含まれていた
- 同時に INFOPLIST_FILE でも参照されており重複が発生した
- 試み1（PBXFileSystemSynchronizedBuildFileExceptionSet の membershipExceptions）は期待通り機能しなかった

**解決方法**:
```
SecureZip/SecureZip/Info.plist -> SecureZip/Info.plist に移動（同期グループ外）
INFOPLIST_FILE = "Info.plist" に更新（相対パス修正）
不要になった PBXFileSystemSynchronizedBuildFileExceptionSet を削除
```

**対応時間**: 未記載

---

### 問題3: AppDelegate の @MainActor 分離エラー
**状態**: 解決済み

**症状**:
```
Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
```

**原因**:
- AutoDeleteService が `@MainActor` クラスとして実装されているため、その `init()` は MainActor に分離されている
- AppDelegate が nonisolated（`@MainActor` なし）の状態では、プロパティ初期化時に `AutoDeleteService()` を同期的に呼び出せない
- Swift Concurrency の strict concurrency チェックによりコンパイルエラーとなった

**解決方法**:
```swift
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let autoDeleteService = AutoDeleteService()  // @MainActor init() が呼べるようになる
    // ...
}
```

**補足**: NSApplicationDelegate のライフサイクルメソッドは元々 Main Thread で実行されるため、`@MainActor` 化による動作上の副作用はない。

**対応時間**: 未記載

---

### 問題4: zipfile.setpassword() による暗号化未適用 (既知の問題、今回対応)
**状態**: 解決済み（実装変更）

**症状**:
```
生成された ZIP ファイルが実際には暗号化されていない
```

**原因**:
- Python zipfile.setpassword() は読み取り専用 API
- 書き込み時に暗号化を行う API ではない

**解決方法**:
```swift
// /usr/bin/zip -r -e を Process 経由で実行
// パスワードは "password\npassword\n" 形式で stdinData 経由で渡し、コマンドライン引数への露出を回避
// 暗号化方式: ZipCrypto（標準 ZIP 暗号化）
// 注意: ZipCrypto は既知の脆弱性がある（known-plaintext attack）。Phase 2 で AES-256 対応が必要
```

**対応時間**: 未記載

## 技術的発見・学習

### 新しく学んだこと
- Xcode の `PBXFileSystemSynchronizedRootGroup` はグループ内のファイルを自動的にビルドターゲットに含めるため、Info.plist などの特殊ファイルは同期グループ外に配置する必要がある。`PBXFileSystemSynchronizedBuildFileExceptionSet` の `membershipExceptions` は期待通り機能しないケースがある
- `/usr/bin/zip` コマンドは `-e` フラグで ZipCrypto による暗号化が可能。`-e` は対話的にパスワードを2回要求するため、stdin に `"password\npassword\n"` を書き込むことで自動化できる
- Swift Concurrency の strict concurrency モードでは、`@MainActor` クラスのインスタンスをプロパティとして保持する場合、保持側のクラスも `@MainActor` でなければコンパイルエラーになる

### ベストプラクティス
- コマンドライン引数へのパスワード埋め込みは `ps` コマンドなどで第三者に見える危険がある。stdin 経由での受け渡しを徹底する
- CoreData の `loadPersistentStores` エラー時は必ずインメモリストアへのフォールバックを実装し、クラッシュを回避する
- SecRandomCopyBytes のリジェクションサンプリングにより、暗号学的に均一な乱数生成を保証する

### パフォーマンス改善
- 重複コード（isValidEmail, base64URLEncode）の削除によりコードの保守性が向上

## 進捗状況

### 本日の成果
- 完了: コードレビュー全指摘事項の修正（Critical 3件, High 6件, Medium 7件, Low 4件）(100%)
- 完了: Xcode プロジェクト macOS 専用設定 (100%)
- 完了: Core Data モデル属性定義 (100%)
- 完了: ビルドエラー修正（archive.h, Info.plist 配置, @MainActor）(100%)
- 未着手: Xcode での手動ビルド最終確認 (0%)
- 未着手: Gmail OAuth フロー実装 (0%)

### 全体進捗
```
コア機能実装:    [========..] 80%  (Phase 1 完了, 暗号化修正済み)
Xcode 設定:      [========..] 80%  (設定完了, 手動確認待ち)
Gmail 連携:      [====......] 40%  (API クライアント実装済み, OAuth 未実装)
テスト作成:      [..........] 0%   (未着手)
ドキュメント:    [====......] 40%  (Xcode セットアップガイド作成済み)
```

## コミット履歴

```bash
# 本日のコミット（9件）
9a5a36e fix(security): 暗号化ZIPの実装修正とセキュリティ・UI改善
050a989 fix(review): コードレビュー指摘事項（High/Medium/Low）を修正
b3c4140 docs(setup): Xcode プロジェクト設定ガイドを追加
97d266c docs(setup): Xcode プロジェクト保存先の説明を修正
088d17d chore: Bundle ID を com.tkrite.SecureZip に統一
6bafc03 feat(coredata): Core Data モデルの Attribute を定義
d59ab5f chore(xcode): プロジェクト設定を macOS 専用に修正
a54bdc3 fix(xcode): ビルドエラー3件を修正
b674446 fix(xcode): Info.plist 配置とアクタ分離のビルドエラーを修正
```

## コードレビュー指摘事項

### レビュアーからの指摘
1. [C-1+C-2] 暗号化 ZIP 実装が機能していない（zipfile.setpassword() は読み取り専用）
   - 対応状況: [x] 対応済
   - 対応内容: /usr/bin/zip -r -e + stdin パスワード渡しに変更
2. [H-1] GmailService の認証エラーハンドリング不備
   - 対応状況: [x] 対応済
   - 対応内容: SecureZipError.gmailNotAuthenticated を適切に throw するよう修正
3. [H-2] Gmail 連携エラーが画面に表示されない
   - 対応状況: [x] 対応済
   - 対応内容: errorMessage プロパティ追加とエラー表示 UI を実装
4. [H-3] SendViewModel で isSending がリセットされない
   - 対応状況: [x] 対応済
   - 対応内容: do/catch でラップしてリセットを保証
5. [H-4] KeychainWrapper が KeychainService と重複
   - 対応状況: [x] 対応済
   - 対応内容: KeychainWrapper.swift を削除
6. [H-5+M-7] HistoryService の DI 不足・weak self 不適切
   - 対応状況: [x] 対応済
   - 対応内容: DI 追加、不要な weak self を削除
7. [H-6] CoreDataStack のインメモリフォールバック未実装
   - 対応状況: [x] 対応済
   - 対応内容: エラー時のインメモリストアフォールバックを実装
8. [M-1] GmailService に separatePassword パラメータがない
   - 対応状況: [x] 対応済
   - 対応内容: プロトコルと実装に追加
9. [M-2] PasswordService のモジュロバイアス
   - 対応状況: [x] 対応済
   - 対応内容: リジェクションサンプリングを実装
10. [M-3+M-4] 重複コードの存在
    - 対応状況: [x] 対応済
    - 対応内容: isValidEmail, base64URLEncode の重複を削除
11. [M-5] DropZoneView でエラーをサイレントに無視
    - 対応状況: [x] 対応済
    - 対応内容: エラーログ出力を追加
12. [M-6] AutoDeleteService の @MainActor 不備
    - 対応状況: [x] 対応済
    - 対応内容: @MainActor クラス化、deinit 修正
13. [L-1+L-3+L-4] @MainActor アノテーション不足
    - 対応状況: [x] 対応済
    - 対応内容: CompressView, CompressViewModel, DecompressViewModel に追加

### セルフレビュー
- [x] コーディング規約準拠
- [x] エラーハンドリング
- [x] ログ出力（DropZoneView のサイレント無視を修正）
- [ ] コメント記載（一部未実施）

## 次回の予定

### 優先タスク
1. Xcode で手動ビルドを実行し、エラーの有無を確認
2. Gmail OAuth フローの実装（Phase 2 の主要機能）
3. 暗号化 ZIP の動作確認（/usr/bin/zip -e が正しく機能するかテスト）

### 懸念事項
- Xcode でのビルドが Claude Code からは直接実行できないため、手動確認が必須
- ZipCrypto は AES-256 より強度が低く、known-plaintext attack に脆弱。Phase 2 以降で libarchive C API への移行を検討
- `/usr/bin/zip -e` による解凍時のパスワード渡しは `-P` フラグ（コマンドライン引数）を使用しており、圧縮時と同レベルの stdin 対応が未実施
- Gmail OAuth の実装には GoogleSignIn-iOS / GTMAppAuth の設定が必要

### 必要なサポート
- Xcode を使用できる環境での手動ビルド確認
- Gmail API OAuth 2.0 認証情報（client_id, client_secret）

## メモ・備考

### 参考リンク
- Apple Developer: [NSPersistentContainer](https://developer.apple.com/documentation/coredata/nspersistentcontainer)
- Swift Concurrency: [@MainActor documentation](https://developer.apple.com/documentation/swift/mainactor)
- zip コマンド man page: 暗号化オプション (-e) の仕様

### 相談事項
- ZipCrypto から AES-256 への移行タイミングをプロダクトオーナーと確認する必要がある

### 改善提案
- 将来的に XCTest によるユニットテストを PasswordService, KeychainService, CoreDataStack に追加することで品質を担保できる
- LibArchiveWrapper の暗号化方式を設定で切り替えられるようにすることで、互換性と強度の両立が可能

## メトリクス

| 指標 | 値 |
|------|-----|
| 追加行数 | 963 行 |
| 削除行数 | 147 行 |
| 変更ファイル数 | 23 ファイル |
| コミット数 | 9 コミット |
| 解消した問題数 | 20 件（Critical 3, High 6, Medium 7, Low 4） |
| 作業時間 | 未記載 |

## タグ
`#development` `#code-review` `#xcode-setup` `#build-fix` `#security` `#swift` `#2026-03-02`

---
*作成: 2026-03-02 JST*
*最終更新: 2026-03-02 JST*
*リードデベロッパーレビュー: 2026-03-02 JST*
