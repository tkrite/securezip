# 開発ログ - 2026-03-05

## 基本情報
- **日付**: 2026-03-05
- **開発者**: Claude Code
- **ブランチ**: `master`
- **関連Issue**: F014（スコープ外・見送り）
- **プロジェクトフェーズ**: Phase 5（App Store 申請準備）進行中
- **関連ログ**: `2026-03-05_dev-phase3-completion.md`（同日 Phase 3 完了・F013 先行実装ログ）

## 本日の開発目標
### 計画タスク
- [x] App Store 審査リスク解消（システム libarchive への移行） - 優先度: 高
- [x] アプリアイコン作成・配置 - 優先度: 高
- [x] Universal Binary 対応確認 - 優先度: 高
- [x] プライバシーポリシー作成・公開 - 優先度: 高
- [x] 多言語対応（日本語・英語） - 優先度: 中
- [ ] 多言語対応の動作確認 - 優先度: 中（翌日実施予定）
- [ ] Google OAuth 本番審査申請 - 優先度: 中（次ステップ）
- [ ] App Store Connect 設定 - 優先度: 中（次ステップ）

### 完了条件
- `com.apple.security.cs.disable-library-validation` エンタイトルメントを削除してもビルド・動作が成功すること
- アプリアイコンが全サイズで正しく配置されること
- プライバシーポリシーが外部 URL でアクセス可能なこと
- 多言語リソースが Xcode プロジェクトに認識されること

## 実装内容

### 1. App Store リスク解消：システム libarchive への移行
**作業時間**: 未記録

#### 実装概要
```
Homebrew 製 libarchive を使用していたことで必要だった
com.apple.security.cs.disable-library-validation エンタイトルメントを削除するため、
macOS システム付属の libarchive（/usr/lib/libarchive.2.dylib）へ移行した。
```

#### 技術的詳細
```bash
# ヘッダーファイルをプロジェクト内にコピー（Homebrew 版を流用）
cp /opt/homebrew/opt/libarchive/include/archive.h \
   SecureZip/SecureZip/Infrastructure/Headers/
cp /opt/homebrew/opt/libarchive/include/archive_entry.h \
   SecureZip/SecureZip/Infrastructure/Headers/

# システム libarchive の AES-256 API 存在確認
# archive_write_set_passphrase / archive_write_set_options /
# archive_read_add_passphrase の存在を TBD にて確認済み
```

> **注意: ヘッダーの互換性リスク**
> Homebrew 版ヘッダーをシステム libarchive で使用している。TBD で主要シンボルの存在は確認済みだが、
> Homebrew 版ヘッダーとシステム版 dylib のバージョン差によるマイナーな API 不整合のリスクがある。
> より安全な方法は macOS SDK 付属のヘッダー
> （`/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/archive.h`）を使用すること。
> 現時点ではビルド・動作とも問題ないことを確認済みだが、今後問題が発生した場合は SDK 版への切替を検討する。

**project.pbxproj の変更点**:
- `HEADER_SEARCH_PATHS`: Homebrew パス（`/opt/homebrew/opt/libarchive/include`）→ `$(SRCROOT)/SecureZip/Infrastructure/Headers`
- `LIBRARY_SEARCH_PATHS`: Homebrew パス削除（システム libarchive を自動参照）

**エンタイトルメントの変更**:
- `com.apple.security.cs.disable-library-validation` を `SecureZip.entitlements` から削除

**変更後のエンタイトルメント構成（全量）**:
- `com.apple.security.app-sandbox` = true
- `com.apple.security.network.client` = true（Gmail API 通信用）
- `com.apple.security.files.user-selected.read-write` = true
- `com.apple.security.files.downloads.read-write` = true
- `keychain-access-groups` = `$(AppIdentifierPrefix)com.tkrite.SecureZip`

#### 変更ファイル
- `SecureZip/SecureZip.xcodeproj/project.pbxproj` - HEADER_SEARCH_PATHS / LIBRARY_SEARCH_PATHS 変更
- `SecureZip/SecureZip/SecureZip.entitlements` - disable-library-validation エンタイトルメント削除
- `SecureZip/SecureZip/Infrastructure/Headers/archive.h` - 新規追加
- `SecureZip/SecureZip/Infrastructure/Headers/archive_entry.h` - 新規追加

### 2. アプリアイコン作成・配置
**作業時間**: 未記録

#### 実装概要
```
ユーザーが 1024x1024 PNG アイコン（青背景・フォルダ・南京錠・封筒のデザイン）を作成し、
sips コマンドで macOS 必要サイズ 10種を生成して Assets.xcassets に配置した。
Contents.json を macOS 専用構成（iOS エントリ削除）に更新した。
```

#### 技術的詳細
```bash
# sips で各サイズを生成（16, 32, 64, 128, 256, 512, 1024 px および @2x 相当）
# 注: 出力ファイル名は実際には icon_* プレフィックスで配置（下記はコマンド例）
sips -z 16 16   AppIcon.png --out icon_16x16.png
sips -z 32 32   AppIcon.png --out icon_16x16@2x.png
sips -z 32 32   AppIcon.png --out icon_32x32.png
sips -z 64 64   AppIcon.png --out icon_32x32@2x.png
sips -z 128 128 AppIcon.png --out icon_128x128.png
sips -z 256 256 AppIcon.png --out icon_128x128@2x.png
sips -z 256 256 AppIcon.png --out icon_256x256.png
sips -z 512 512 AppIcon.png --out icon_256x256@2x.png
sips -z 512 512 AppIcon.png --out icon_512x512.png
sips -z 1024 1024 AppIcon.png --out icon_512x512@2x.png
```

#### 変更ファイル
- `SecureZip/SecureZip/Assets.xcassets/AppIcon.appiconset/` - 全サイズアイコン追加（icon_* 命名）
- `SecureZip/SecureZip/Assets.xcassets/AppIcon.appiconset/Contents.json` - macOS 専用構成に更新

### 3. Universal Binary 対応確認
**作業時間**: 未記録

#### 実装概要
```
追加設定なしで Universal Binary（arm64 + x86_64）が自動生成されることを確認した。
```

#### 技術的詳細
```
確認した設定状態:
- ARCHS: 未指定（$(ARCHS_STANDARD) デフォルト）→ arm64 + x86_64 を自動対象
- ONLY_ACTIVE_ARCH = YES: Debug ビルドのみ（Release には非適用）
- EXCLUDED_ARCHS: 設定なし
- システム libarchive TBD: arm64-macos / x86_64-macos 両スライスの存在を確認済み

結論: 追加設定不要。Release ビルドで Universal Binary が自動生成される。
```

> **未確認事項: デプロイターゲット**
> 同日の Phase 3 ログで MACOSX_DEPLOYMENT_TARGET が 15.0 に引き上げられている。
> システム libarchive への移行により Homebrew 依存が解消されたため、要件定義書どおり
> macOS 13 への引き下げが技術的に可能になったが、本セッションでは変更を実施していない。
> Phase 5 残タスクとして対応が必要。

#### 変更ファイル
- なし（確認のみ、設定変更不要）

### 4. プライバシーポリシー作成・公開
**作業時間**: 未記録

#### 実装概要
```
App Store Connect および Google Cloud Console OAuth 同意画面への登録に必要な
プライバシーポリシーを HTML で作成し、GitHub Pages で公開した。
Google API Services User Data Policy に準拠した記述を含む。
日本語・英語の切り替え機能を実装。
```

#### 技術的詳細
```
公開 URL: https://murakami-akane.github.io/securezip-privacy/

Google Cloud Console 設定:
- OAuth 同意画面にプライバシーポリシー URL を登録
- 承認済みドメインに github.io を追加して解決
- App Store Connect への登録は次ステップ
```

#### 変更ファイル
- 別リポジトリ（`securezip-privacy`）に HTML を作成し GitHub Pages でデプロイ
- 本プロジェクト内には配置していない（GitHub Pages 専用リポジトリで管理）

### 5. 多言語対応（日本語・英語）
**作業時間**: 未記録

#### 実装概要
```
全 View の日本語テキストを抽出し（9 ファイル、約 70 文字列）、
ja.lproj / en.lproj 配下に Localizable.strings を作成した。
Xcode 16 のファイル自動同期により、プロジェクトに
Localizable (English) / Localizable (Japanese) として認識されていることを確認済み。
動作確認は翌日（再起動後）実施予定。
```

> **確認事項**: ja.lproj (3824 bytes) と en.lproj (3398 bytes) にサイズ差がある。
> 翻訳キーの過不足がないか翌日の動作確認時に合わせて検証する。

#### 変更ファイル
- `SecureZip/SecureZip/Resources/ja.lproj/Localizable.strings` - 新規作成（日本語）
- `SecureZip/SecureZip/Resources/en.lproj/Localizable.strings` - 新規作成（英語）
- `SecureZip/SecureZip/Resources/Localizable.strings` - 削除（旧ファイル）

## テスト実施

### ユニットテスト
- 未実施（未記録）

### 動作確認
| 機能 | 結果 | 備考 |
|-----|------|------|
| システム libarchive での圧縮 | 確認済み | 問題なし |
| システム libarchive での解凍 | 確認済み | 問題なし |
| AES-256 暗号化圧縮（システム版） | 確認済み | Homebrew 版と同等の動作を確認 |
| アプリアイコン配置 | 確認済み | 全サイズ配置完了 |
| Universal Binary（設定確認） | 確認済み | 追加設定不要と判断 |
| プライバシーポリシー URL アクセス | 確認済み | GitHub Pages で公開済み |
| 多言語リソース Xcode 認識 | 確認済み | 自動同期で認識 |
| 多言語対応 実機動作 | 未確認 | 翌日実施予定 |

## 発生した問題と解決

### 問題1: Homebrew libarchive が Hardened Runtime に引っかかる
**発生時刻**: 未記録

**症状**:
```
Homebrew 製 libarchive は Apple とは異なる Team ID を持つため、
Hardened Runtime の library validation を通過するために
com.apple.security.cs.disable-library-validation が必要だった。
このエンタイトルメントは App Store 審査でリジェクトリスクがある。
```

**原因**:
- Homebrew パッケージは Apple の Developer ID で署名されていないため

**解決方法**:
```bash
# macOS システム付属の libarchive を使用するよう移行
# /usr/lib/libarchive.2.dylib はシステムライブラリのため
# library validation の対象外（追加エンタイトルメント不要）

# ヘッダーをプロジェクト内に取り込み、
# HEADER_SEARCH_PATHS を更新して Homebrew 依存を排除
```

**対応時間**: 未記録

### 問題2: Google OAuth 同意画面でプライバシーポリシー URL が拒否される
**状態**: 解決済み

**症状**:
```
Google Cloud Console の OAuth 同意画面にプライバシーポリシー URL を登録しようとした際、
ドメインが承認済みドメインとして認識されなかった。
```

**解決方法**:
```
承認済みドメインに github.io を追加することで解決。
```

**対応時間**: 未記録

## 技術的発見・学習

### 新しく学んだこと
- macOS システム付属の libarchive（`/usr/lib/libarchive.2.dylib`）でも AES-256 暗号化 API（`archive_write_set_passphrase` 等）が利用可能であることを確認
- `ONLY_ACTIVE_ARCH = YES` は Debug ビルドのみに適用され、Release ビルドでは `$(ARCHS_STANDARD)` により arm64 + x86_64 の Universal Binary が自動生成される
- Xcode 16 のファイル自動同期機能により、`ja.lproj` / `en.lproj` 配下のファイルはプロジェクトへの手動追加なしに認識される

### ベストプラクティス
- App Store 配布アプリではシステムライブラリを優先的に使用し、サードパーティライブラリの署名問題を回避する
- プライバシーポリシーは GitHub Pages 等の安定したホスティングで公開し、Google / Apple 両プラットフォームに登録する

### パフォーマンス改善
- 未記載（本セッションは App Store 申請準備が主目的のため、パフォーマンス改善は対象外）

## 進捗状況

### 本日の成果
- 完了: システム libarchive 移行（disable-library-validation 削除）(100%)
- 完了: アプリアイコン作成・配置 (100%)
- 完了: Universal Binary 対応確認 (100%)
- 完了: プライバシーポリシー作成・GitHub Pages 公開 (100%)
- 完了: 多言語リソース作成（Xcode 認識済み）(100%)
- 進行中: 多言語対応 動作確認 (0%、翌日実施予定)
- 未着手: Google OAuth 本番審査申請 (0%)
- 未着手: TestFlight 配布 (0%)
- 未着手: App Store Connect 設定 (0%)

### 全体進捗
```
Phase 1（コア圧縮・解凍）: [##########] 100%
Phase 2（AES-256 暗号化）: [##########] 100%
Phase 3（Gmail 連携）:     [##########] 100%
Phase 4（F013 元ファイル処理）: [##########] 100%
Phase 5（App Store 申請準備）:  [#######...]  70%
```

## コミット履歴

```bash
# 本日のコミット（Phase 5 関連、セッション中の記録）
# - システム libarchive 移行、エンタイトルメント更新
# - アプリアイコン配置・Contents.json 更新
# - プライバシーポリシー HTML 作成（別リポジトリ）
# - 多言語対応（ja.lproj / en.lproj）
# 注: 個別コミットの hash は未記録
# 注: Phase 5 の変更はまだコミットされていない可能性あり。
#     git status で未コミットの変更を確認し、適切にコミットすること。
```

## コードレビュー指摘事項

### レビュアーからの指摘
- 未記載（本セッションはドキュメント作成フォーカスのためレビュー未実施）

### セルフレビュー
- [x] コーディング規約準拠
- [x] エラーハンドリング（libarchive API の利用方法は既存実装を継承）
- [ ] ログ出力（未確認）
- [x] コメント記載（ヘッダーファイルは libarchive 公式のものをそのまま使用）

## 意思決定記録

### F014（Curve25519 公開鍵暗号）スコープ外
- **判断**: 見送り（スコープ外）
- **理由**: 受信者側の鍵管理（公開鍵の配布・管理）の負担が高く、一般ビジネスユーザー向けアプリとして現実的でないと判断。AES-256 パスワード暗号化で要件を満たす。

### disable-library-validation 削除
- **判断**: システム libarchive に移行して削除
- **理由**: App Store 審査リスクを回避。システム版でも AES-256 API が利用可能であることを確認済みのため、機能上の影響なし。

### ヘッダーファイルの選択
- **判断**: Homebrew 版の archive.h / archive_entry.h をプロジェクト内にコピーして使用
- **理由**: 開発環境に Homebrew 版が既にインストールされており、即座に利用可能だったため。macOS SDK 版ヘッダーの使用も検討したが、Homebrew 版の方が API ドキュメントコメントが豊富であることを考慮した。今後 API 不整合が発生した場合は SDK 版への切替を検討する。

### プライバシーポリシー公開先
- **判断**: GitHub Pages（`github.io`）を採用
- **理由**: 無料・安定・HTTPS 対応。Google / Apple 両プラットフォームへの登録に適している。

## 明日の予定

### 優先タスク
1. **デプロイターゲット再確認** -- MACOSX_DEPLOYMENT_TARGET を macOS 13 に戻せるか検証・実施
2. 多言語対応（日英）の動作確認（システム言語切り替えで表示が変わることを検証）
3. Localizable.strings の日英キー整合性チェック（サイズ差の確認）
4. Google OAuth 本番審査申請（OAuth 同意画面の公開申請）
5. App Store Connect 設定（バンドル ID `com.tkrite.SecureZip` 確認、スクリーンショット準備等）

### 未対応の App Store 申請必須事項
- [ ] **Privacy Manifest（PrivacyInfo.xcprivacy）の作成** -- 2024年5月以降 App Store 必須。Keychain Services / FileManager 等の Required Reason API 使用を申告する必要がある
- [ ] **デプロイターゲットの macOS 13 への再引き下げ** -- 要件定義書との整合性を確保
- [ ] **EAR（暗号化輸出規制）自己分類の確認** -- AES-256 暗号化使用のため、App Store Connect で暗号化申告が必要
- [ ] **コード署名設定の確認** -- Automatic Signing / Team ID の設定
- [ ] **macOS 13 での互換ビルド・動作確認**

### 懸念事項
- 多言語対応でシステム言語切り替えが正しく反映されない可能性がある（再起動後に確認）
- Google OAuth 本番審査に時間がかかる場合、TestFlight 配布のタイミングに影響する
- Homebrew 版ヘッダーとシステム libarchive のバージョン差による潜在的な API 不整合リスク
- Privacy Manifest 未作成が App Store リジェクトの原因となる可能性

### 必要なサポート
- App Store Connect のスクリーンショット作成（各言語・各サイズ）
- Privacy Manifest に記載すべき Required Reason API の洗い出し

## メモ・備考

### 参考リンク
- プライバシーポリシー公開 URL: `https://murakami-akane.github.io/securezip-privacy/`
- Google API Services User Data Policy: `https://developers.google.com/terms/api-services-user-data-policy`
- Privacy Manifest 公式ドキュメント: `https://developer.apple.com/documentation/bundleresources/privacy_manifest_files`

### 相談事項
- Homebrew 版ヘッダーを macOS SDK 版に差し替えるべきか（現時点では動作に問題なし）
- デプロイターゲットを macOS 13 に戻す際に、API 互換性テストをどの程度行うか

### 改善提案
- Phase 5 のチェックリストを独立したドキュメントとして作成し、申請準備の進捗を可視化することを推奨

## メトリクス

| 指標 | 値 |
|------|-----|
| 追加行数 | 未記録 |
| 削除行数 | 未記録 |
| 変更ファイル数 | 9（追加 8、削除 1）※プライバシーポリシーは別リポジトリ |
| 作業時間 | 未記録 |
| 生産性 | 高（App Store 申請準備の主要タスクを完了） |

## タグ
`#development` `#phase5` `#appstore` `#libarchive` `#localization` `#privacy-policy` `#universal-binary` `#2026-03-05`

---
*作成: 2026-03-05 JST*
*最終更新: 2026-03-05 JST（lead-developer レビューによる修正）*
