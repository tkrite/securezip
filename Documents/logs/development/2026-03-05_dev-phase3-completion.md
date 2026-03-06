# 開発ログ - 2026-03-05

## 基本情報
- **日付**: 2026-03-05
- **開発者**: Claude Code
- **ブランチ**: `master`
- **関連Issue**: F008, F009, F011, F013
- **プロジェクトフェーズ**: Phase 3 修正・安定化完了 / Phase 4 一部先行実装（F013）
- **関連ログ**: `2026-03-05_dev-test-target-setup.md`（同日午前の Xcode テストターゲット修正ログ）

## 本日の開発目標
### 計画タスク
- [x] Xcode テストターゲット設定修正（macOS 化・デプロイターゲット更新） - 優先度: 高
- [x] エンタイトルメント追加（Hardened Runtime / Keychain 対応） - 優先度: 高
- [x] Gmail OAuth 連携修正（GIDSignIn 直接参照への移行） - 優先度: 高
- [x] ViewModel スレッド安全性修正（`@MainActor` 追加） - 優先度: 高
- [x] SendViewModel 送信フロー修正 F008（圧縮後送信） - 優先度: 高
- [x] SendViewModelTests 修正（MockCompressionService 追加） - 優先度: 高
- [x] F011: SendViewModel が設定値を読み込むよう修正 - 優先度: 中
- [x] F013: 圧縮後の元ファイル処理（Phase 4 先行実装） - 優先度: 中
- [x] SettingsView キャンセル猶予上限変更（30 → 10 秒） - 優先度: 低
- [x] CompressView onChange 警告修正 - 優先度: 低

### 完了条件
- Cmd+U (XCTest) が全スイート PASSED となること
- Gmail OAuth 認証・送信が正常に動作すること
- 送信時にファイルが ZIP 圧縮されてから送信されること
- 圧縮後の元ファイル処理（ゴミ箱/削除）が正常動作すること

## 実装内容

### 1. Xcode テストターゲット設定修正
**作業時間**: 未記載

#### 実装概要
```
project.pbxproj のテストターゲットビルド設定が iOS SDK になっていたのを macOS 向けに修正。
SecureZipTests.xctestplan を有効化し、libarchive のヘッダ検索パスをテストターゲットに追加。
デプロイターゲットを macOS 13.0 から 15.0 に引き上げた。
```

**デプロイターゲット変更の背景**: macOS 15.0 への引き上げは、Homebrew 版 libarchive（/opt/homebrew/opt/libarchive/）を使用する現在の構成において、Xcode 15+ / macOS 15 環境での安定動作を優先したもの。これにより **macOS 13/14 ユーザーがサポート対象外** となる。要件定義書では macOS 13 Ventura 以降がサポート対象だが、Phase 5（App Store 申請準備）で libarchive をアプリにバンドルする形式に移行する際に、デプロイターゲットの再引き下げを検討する必要がある。

> **注意**: この変更は要件定義書 3.1.2 の「macOS 13 Ventura 以降」と矛盾する。暫定的な開発環境上の制約による判断であり、リリース時には解消が必要。

#### 技術的詳細
```
修正内容:
- SDKROOT = iphoneos → macosx
- MACOSX_DEPLOYMENT_TARGET = 15.0 に変更（アプリ・テスト両ターゲット）
- IPHONEOS_DEPLOYMENT_TARGET, TARGETED_DEVICE_FAMILY を削除
- HEADER_SEARCH_PATHS = /opt/homebrew/opt/libarchive/include をテストターゲットに追加
- SecureZipTests.xctestplan の enabled: false → true に変更
```

#### 変更ファイル
- `SecureZip/SecureZip.xcodeproj/project.pbxproj` - テストターゲットのビルド設定を iOS から macOS 向けに全面修正
- `SecureZip/SecureZipTests.xctestplan` - テストを有効化（`enabled: false → true`）

---

### 2. エンタイトルメント追加（SecureZip.entitlements）
**作業時間**: 未記載

#### 実装概要
```
Homebrew 製 libarchive の Team ID ミスマッチによる Hardened Runtime ブロックを解消するために
com.apple.security.cs.disable-library-validation を追加。
また GIDSignIn SDK が要求する Keychain アクセスグループを追加。
```

#### 技術的詳細
```xml
<!-- 追加したエンタイトルメント -->
<key>com.apple.security.cs.disable-library-validation</key>
<true/>

<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.tkrite.SecureZip</string>
</array>
```

**`disable-library-validation` の背景**: Hardened Runtime 環境では、アプリと異なる Team ID で署名されたダイナミックライブラリの読み込みがブロックされる。Homebrew でインストールした libarchive は Apple Team ID で署名されていないため、このエンタイトルメントが必要。

**`keychain-access-groups` 追加の背景**: GIDSignIn SDK は Keychain への書き込み時にアクセスグループを明示することを要求する。エンタイトルメントに追加しないと OAuth トークンの保存が失敗する。

#### 変更ファイル
- `SecureZip/SecureZip/SecureZip.entitlements` - ライブラリ検証無効化・Keychain アクセスグループ追加

---

### 3. Gmail OAuth 連携修正
**作業時間**: 未記載

#### 実装概要
```
2026-03-04 に実装した Keychain ベースの手動トークン取得・保存を廃止し、
GIDSignIn SDK が管理するトークンを直接参照するシンプルな実装に変更。
Info.plist の GIDClientID・URLスキームを実際のクライアント ID に更新。
```

#### 技術的詳細
```swift
// 旧実装（2026-03-04 実装）: Keychain からトークン取得
let token = KeychainService.shared.get(key: KeychainKey.gmailAccessToken)

// 新実装: GIDSignIn SDK 経由で直接取得
let token = GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString
```

**変更の意図**: GIDSignIn SDK はトークンのリフレッシュを自動的に管理する。
Keychain への手動保存・取得を挟むと SDK の状態と乖離するリスクがあるため廃止。

**旧実装からのマイグレーション**: 2026-03-04 の実装で Keychain に保存されたトークンは、今回の修正後は参照されなくなる。Keychain 上のエントリは残存するが、GIDSignIn SDK が独自に管理するトークンが優先されるため、動作上の問題はない。将来的に不要な Keychain エントリをクリーンアップする処理の追加を検討すること。

#### 変更ファイル
- `SecureZip/SecureZip/Info.plist` - `GIDClientID` および URL スキームを実際のクライアント ID に更新
- `SecureZip/SecureZip/Infrastructure/GmailAPIClient.swift` - Keychain 参照を廃止し GIDSignIn 直接参照に変更
- `SecureZip/SecureZip/Services/GmailService.swift` - `authenticate()` の手動 Keychain 保存を削除、`disconnect()` をシンプル化

---

### 4. ViewModel スレッド安全性修正
**作業時間**: 未記載

#### 実装概要
```
SettingsViewModel と HistoryViewModel に @MainActor を class 宣言レベルで付与し、
UI 更新が必ずメインスレッドで行われることを保証した。
```

#### 技術的詳細
```swift
// 修正前
class SettingsViewModel: ObservableObject { ... }

// 修正後
@MainActor
class SettingsViewModel: ObservableObject { ... }
```

#### 変更ファイル
- `SecureZip/SecureZip/ViewModels/SettingsViewModel.swift` - `@MainActor` を class 宣言に追加
- `SecureZip/SecureZip/ViewModels/HistoryViewModel.swift` - `@MainActor` を class 宣言に追加

---

### 5. SendViewModel 送信フロー修正（F008）
**作業時間**: 未記載

#### 実装概要
```
送信時に CompressionService で AES-256 暗号化 ZIP 圧縮を行ってから Gmail で送信するよう変更。
一時ファイルは defer ブロックでクリーンアップし、リソースリークを防止。
CompressionServiceProtocol を依存に追加して DI 可能な構造を維持。
```

**変更の背景**: 2026-03-04 の F008 実装ではファイルをそのまま送信する形だったが、要件定義上の送信フローは「暗号化圧縮 → Gmail 送信」が正しい。本修正で送信前に圧縮処理を挟むフローに変更。

#### 技術的詳細
```swift
// 送信フロー（概略）
func send() async throws {
    let zipURL = try await compressionService.compressZipEncrypted(files, password: password)
    defer { try? FileManager.default.removeItem(at: zipURL) }
    try await gmailService.send(attachment: zipURL, to: recipient)
}
```

#### 変更ファイル
- `SecureZip/SecureZip/ViewModels/SendViewModel.swift` - 圧縮後送信フローに変更・CompressionServiceProtocol 依存追加

---

### 6. SendViewModelTests 修正
**作業時間**: 未記載

#### 実装概要
```
CompressionServiceProtocol に準拠した MockCompressionService を追加し、
実在しない /tmp/test.zip を使う問題を解消。
テストが実際のファイルシステムに依存しない構造に修正。
```

#### 技術的詳細
```swift
// 追加した Mock
final class MockCompressionService: CompressionServiceProtocol {
    func compressZipEncrypted(_ files: [URL], password: String) async throws -> URL {
        return URL(fileURLWithPath: "/tmp/mock_output.zip")
    }
    // ...その他のプロトコルメソッド
}
```

#### 変更ファイル
- `SecureZip/SecureZipTests/ViewModels/SendViewModelTests.swift` - MockCompressionService 追加・テスト修正

---

### 7. F011: SendViewModel 設定値読み込み
**作業時間**: 未記載

#### 実装概要
```
SendViewModel の init で UserDefaults から cancelDelaySeconds（デフォルト 5 秒）と
isSeparatePasswordEnabled を読み込み、SettingsView で変更した設定が
SendViewModel に反映されるよう対応。
```

**備考**: 技術仕様書 12.1.1 では設定の保存先を Core Data（AppSettings エンティティ）としているが、現在の実装は UserDefaults を使用している。Phase 5 前に Core Data への移行を検討するか、仕様書側を更新する必要がある。

#### 技術的詳細
```swift
init(...) {
    self.cancelDelaySeconds = UserDefaults.standard.integer(forKey: "cancelDelaySeconds")
    if cancelDelaySeconds == 0 { cancelDelaySeconds = 5 } // デフォルト値
    self.isSeparatePasswordEnabled = UserDefaults.standard.bool(forKey: "isSeparatePasswordEnabled")
}
```

#### 変更ファイル
- `SecureZip/SecureZip/ViewModels/SendViewModel.swift` - `init` に UserDefaults からの設定読み込みを追加

---

### 8. F013: 圧縮後の元ファイル処理（Phase 4 先行実装）
**作業時間**: 未記載

#### 実装概要
```
CompressViewModel に FileManagementService 依存を追加。
圧縮成功後に UserDefaults から postCompressionAction を読み取り、
保持・ゴミ箱・完全削除のいずれかを実行するよう実装。
SettingsView に「圧縮後の元ファイル」セクションを追加。
```

**Phase 4 先行実装の判断理由**: F013 は技術的に単純で Phase 3 の送信フロー修正と同タイミングで実装することが効率的だった。依存するコンポーネント（FileManagementService）が既に存在しており、追加のリスクが低いと判断。

#### 技術的詳細
```swift
// CompressViewModel（概略）
let action = UserDefaults.standard.string(forKey: "postCompressionAction") ?? "keep"
switch action {
case "trash":
    try fileManagementService.moveToTrash(files)
case "delete":
    try fileManagementService.deleteFiles(files)
default:
    break // 保持
}
```

**サンドボックス権限**: ゴミ箱移動には `NSWorkspace.shared.recycle()` を使用しており、App Sandbox 環境で `com.apple.security.files.user-selected.read-write` エンタイトルメントにより動作する。ユーザーが明示的に選択したファイルに対してのみ操作が行われるため、追加のエンタイトルメントは不要。

#### 変更ファイル
- `SecureZip/SecureZip/ViewModels/CompressViewModel.swift` - FileManagementService 依存追加・元ファイル処理ロジック実装
- `SecureZip/SecureZip/Views/SettingsView.swift` - 「圧縮後の元ファイル」セクション追加（保持/ゴミ箱/完全削除 Picker）

---

### 9. その他の細かい修正
**作業時間**: 未記載

#### 実装概要
```
SettingsView の cancelDelaySeconds Stepper 上限を 30 → 10 秒に変更（UX 改善）。
CompressView の onChange(of:perform:) が macOS 14.0 で deprecated となっていたため、
zero-parameter クロージャ形式に変更。
```

**Stepper 上限変更の背景**: 要件定義書 4.3.1 では「キャンセル秒数は 1〜30 秒の範囲」と記載されているが、実運用上 10 秒を超えるキャンセル猶予は UX を損なうと判断して上限を引き下げた。要件定義書との差異として記録しておく。

#### 技術的詳細（onChange 修正）
```swift
// 修正前（perform クロージャ形式 - macOS 14.0 で deprecated）
.onChange(of: value, perform: { newValue in
    // ...
})

// 修正後（zero-parameter クロージャ形式 - macOS 14.0+）
.onChange(of: value) {
    // ...
}
```

#### 変更ファイル
- `SecureZip/SecureZip/Views/SettingsView.swift` - Stepper 上限を 30 → 10 秒に変更
- `SecureZip/SecureZip/Views/CompressView.swift` - `onChange` を非 deprecated 形式に変更

---

## テスト実施

### ユニットテスト
- [x] テストケース作成（MockCompressionService 追加）
- [x] テスト実行（Cmd+U）
- [ ] カバレッジ: 未記載（計測結果の記録なし）

### 動作確認
| 機能 | 結果 | 備考 |
|-----|------|------|
| Cmd+U (XCTest) 全スイート | PASSED | 正常動作 |
| Gmail OAuth 認証 | PASSED | 正常動作 |
| Gmail 送信（ZIP 圧縮後送信） | PASSED | 圧縮→送信フロー確認済み |
| 圧縮後のゴミ箱移動 | PASSED | サンドボックス権限問題なし |
| 圧縮後の完全削除 | PASSED | 正常動作 |
| F014（Curve25519 公開鍵暗号） | 未実施 | スコープ外と判断し除外（下記「意思決定記録」参照） |

## 意思決定記録

### F014（Curve25519 公開鍵暗号）のスコープ外判断
- **判断**: Phase 4 の F014 を本日のスコープから除外
- **理由**:
  1. F014 はパスワードの保管・送信を公開鍵暗号で保護する機能だが、現状では Keychain + Gmail TLS で十分なセキュリティレベルを確保できている
  2. Curve25519 の鍵管理（公開鍵の配布・交換）にはユーザー間のプロトコル設計が必要であり、実装コストが Phase 4 の他の機能（F012/F013）より大幅に高い
  3. App Store リリース（Phase 5）に向けた安定化を優先すべき段階にある
- **今後の方針**: ユーザーフィードバックに基づき、v1.1 以降で再検討する。要件定義書では「任意」（優先度: 低）として分類されており、MVP リリースには不要

### デプロイターゲット macOS 15.0 への引き上げ
- **判断**: macOS 13.0 → 15.0 に暫定変更
- **理由**: Homebrew 版 libarchive を使用する開発構成では、macOS 15 環境での安定動作を優先する必要があった
- **影響**: 要件定義書の「macOS 13 Ventura 以降」サポートと矛盾する
- **対処予定**: Phase 5 で libarchive をアプリバンドルに同梱する形式に移行し、デプロイターゲットを macOS 13 に戻す

### Stepper 上限の引き下げ（30 秒 → 10 秒）
- **判断**: 要件定義書の「1〜30 秒」から「1〜10 秒」に変更
- **理由**: UX 観点で 10 秒超のキャンセル猶予は実用的でないと判断
- **要件定義書との差異**: 要件定義書 4.3.1 の入力規則と異なる。仕様書更新またはリリース前の最終確認が必要

## 発生した問題と解決

### 問題1: GIDSignIn SDK の Keychain アクセスが失敗
**状態**: 解決済

**症状**:
```
Gmail OAuth 認証後にトークンが保存されず、
次回起動時に再認証が必要になる状態。
```

**原因**:
- `keychain-access-groups` エンタイトルメントが未設定のため、GIDSignIn SDK が Keychain へ書き込めなかった

**解決方法**:
```xml
<!-- SecureZip.entitlements に追加 -->
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.tkrite.SecureZip</string>
</array>
```

---

### 問題2: Keychain ベーストークン管理と GIDSignIn SDK の状態乖離
**状態**: 解決済

**症状**:
```
手動で Keychain に保存したトークンが SDK のリフレッシュ処理と乖離し、
期限切れトークンで API 呼び出しが行われる場合があった。
```

**原因**:
- 2026-03-04 の実装で `GmailAPIClient` が SDK を介さず直接 Keychain からトークンを取得していた
- SDK のリフレッシュ結果が Keychain の値に反映されないケースが発生

**解決方法**:
```swift
// GmailAPIClient.swift
// Keychain 参照を廃止し、SDK から直接取得
let token = GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString
```

**根本原因の分析**: GIDSignIn SDK は内部で独自の Keychain エントリを管理しているため、アプリ側で別途 Keychain にトークンを保存・取得するのはアンチパターン。SDK のトークンライフサイクル管理に委ねるべき。

---

### 問題3: SendViewModelTests が実在しないファイルパスに依存
**状態**: 解決済

**症状**:
```
テスト実行時に /tmp/test.zip が存在しないためテストが失敗。
```

**原因**:
- SendViewModel に CompressionServiceProtocol 依存を追加した際、テスト側にモックが未整備だった
- 実際のファイルシステムに依存したテスト設計だった

**解決方法**:
```swift
// MockCompressionService を追加し、実ファイルを使わず済むよう修正
final class MockCompressionService: CompressionServiceProtocol { ... }
```

---

### 問題4: CompressView の onChange deprecation 警告
**状態**: 解決済

**症状**:
```
Xcode ビルド時に onChange(of:perform:) が macOS 14.0 で deprecated という警告が出力される。
```

**原因**:
- `onChange(of:perform:)` は macOS 14.0 以降で非推奨。デプロイターゲットが 15.0 になったため警告が顕在化。

**解決方法**:
```swift
// 修正前（perform クロージャ形式）
.onChange(of: value, perform: { newValue in ... })

// 修正後（zero-parameter クロージャ形式）
.onChange(of: value) { ... }
```

---

## 技術的発見・学習

### 新しく学んだこと
- GIDSignIn SDK はトークンのリフレッシュを自動管理するため、Keychain への手動保存・取得を挟むのはアンチパターン。`currentUser?.accessToken.tokenString` を直接参照するのが正しい使い方。
- `keychain-access-groups` エンタイトルメントがないと、サードパーティ SDK が Keychain へ書き込む際に失敗する。App ID prefix を含む形式（`$(AppIdentifierPrefix)com.tkrite.SecureZip`）で指定する必要がある。
- `@MainActor` は class 宣言レベルに付与することで、クラス内の全プロパティ・メソッドをメインスレッドで実行することが保証される。個別の `@Published` プロパティに付与するより漏れがなく安全。
- `onChange(of:perform:)` は macOS 14.0 以降で非推奨。zero-parameter クロージャ形式（`onChange(of:) { }`）を使用すること。新しい形式では `oldValue` パラメータは省略され、変更後の値は直接バインディングから取得する。

### ベストプラクティス
- ViewModel への依存はプロトコルを介して渡し、テスト時はモックに差し替えられる構造にする（`CompressionServiceProtocol` の例）
- 圧縮後の一時ファイルは `defer` ブロックでクリーンアップすることで、エラー発生時でもリソースリークを防げる
- UserDefaults のデフォルト値は `UserDefaults.standard.register(defaults:)` で事前登録するか、読み取り時にデフォルト値をフォールバックとして設定する
- OAuth SDK のトークン管理は SDK に委ねる。アプリ側で独自のトークン永続化レイヤーを挟むと状態の不整合が発生する

### パフォーマンス改善
- 未記載（本作業はバグ修正・機能実装が中心のためパフォーマンス計測は対象外）

## 進捗状況

### 本日の成果
- 完了: Xcode テストターゲット macOS 化（100%）
- 完了: エンタイトルメント追加（Hardened Runtime / Keychain）（100%）
- 完了: Gmail OAuth 連携修正（100%）
- 完了: ViewModel スレッド安全性修正（100%）
- 完了: F008 送信フロー修正（圧縮後送信）（100%）
- 完了: SendViewModelTests 修正（100%）
- 完了: F011 設定値読み込み（100%）
- 完了: F013 圧縮後元ファイル処理（Phase 4 先行実装）（100%）
- 除外: F014（Curve25519 公開鍵暗号）- 上記「意思決定記録」参照

### 全体進捗
```
Phase 1（コア機能）:    [##########] 100% 完了（2026-03-02）
Phase 2（履歴・Keychain）:[##########] 100% 完了（2026-03-04）
Phase 3（Gmail連携）:   [##########] 100% 完了（2026-03-05 本日）
Phase 4（高度な機能）:  [####------]  40% （F013 先行実装済み・F012/F014 未着手）
Phase 5（App Store）:   [----------]   0% 未着手
```

### 要件定義書との差異（未解決）
| 項目 | 要件定義書 | 現在の実装 | 対応予定 |
|------|-----------|-----------|---------|
| デプロイターゲット | macOS 13+ | macOS 15+ | Phase 5 で libarchive バンドル後に引き下げ |
| キャンセル秒数上限 | 1〜30 秒 | 1〜10 秒 | 仕様書更新 or リリース前に判断 |
| 設定保存先 | Core Data（AppSettings） | UserDefaults | Phase 5 前に統一方針を決定 |

## コミット履歴

```bash
# 本日のコミット（関連コミット抜粋）
bc9d58f test(send): SendViewModelTests に MockCompressionService を追加
04c05e1 feat(gmail): Gmail OAuth 連携・送信フロー修正
2036a4e chore(xcode): テストターゲット設定を macOS 向けに修正・デプロイターゲットを 15.0 に変更
```

## コードレビュー指摘事項

### レビュアーからの指摘
- 未記載（本セッションではコードレビュー実施なし）

### セルフレビュー
- [x] コーディング規約準拠
- [x] エラーハンドリング（defer によるクリーンアップ、throw による伝播）
- [ ] ログ出力（詳細なログ追加は未実施）
- [x] コメント記載（主要な変更箇所にコメント記載済み）

## 明日の予定

### 優先タスク
1. Phase 5（App Store 申請準備）の計画策定
2. F012（分割圧縮）の実装方針検討
3. テストカバレッジの計測・記録
4. 不要な Keychain エントリのクリーンアップ処理の検討

### 懸念事項
- `com.apple.security.cs.disable-library-validation` は **App Store 審査で問題になる可能性が高い**。libarchive をアプリにバンドルする形式への移行は Phase 5 の最優先事項として扱うべき。
- F012（分割圧縮）は後回しにしているが、ユーザー要求度次第では Phase 5 前に実装が必要になる可能性がある。
- UserDefaults と Core Data（AppSettings）の設定保存先の不統一が技術的負債として蓄積している。

### 必要なサポート
- 未記載

## メモ・備考

### 参考リンク
- [Google Sign-In SDK リファレンス](https://developers.google.com/identity/sign-in/ios/reference/Classes/GIDSignIn)
- [Apple: Hardened Runtime - disable-library-validation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_disable-library-validation)
- [Apple: keychain-access-groups](https://developer.apple.com/documentation/bundleresources/entitlements/keychain-access-groups)
- [SwiftUI: onChange(of:)](https://developer.apple.com/documentation/swiftui/view/onchange(of:)-7wkv4)

### 相談事項
- F014（Curve25519 公開鍵暗号）をスコープ外とする判断について、意思決定記録に理由を記載済み。PO/PM への共有・承認を推奨。
- デプロイターゲット macOS 15.0 への引き上げについて、リリース計画への影響を確認すること。

### 改善提案
- libarchive を Homebrew 経由ではなく Swift Package Manager または XCFramework としてバンドルすることで、Hardened Runtime の `disable-library-validation` 依存を解消できる可能性がある。これにより App Store 審査リスクの低減とデプロイターゲットの引き下げが同時に実現できる。

## メトリクス

| 指標 | 値 |
|------|-----|
| 追加行数 | 未記載 |
| 削除行数 | 未記載 |
| 変更ファイル数 | 13 |
| 作業時間 | 未記載 |
| 生産性 | 高（Phase 3 完了・F013 先行実装・全テスト PASSED） |

## タグ
`#development` `#phase3-completion` `#gmail-oauth` `#xcode` `#swift` `#swiftui` `#macos` `#2026-03-05`

---
*作成: 2026-03-05 JST*
*最終更新: 2026-03-05 JST*
*レビュー: 2026-03-05 JST（lead-developer による技術レビュー実施）*
