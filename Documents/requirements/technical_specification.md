# SecureZip for Mac - 技術仕様書

## 1. 文書情報

### 1.1 文書概要
- **文書名**: 技術仕様書
- **プロジェクト名**: SecureZip for Mac
- **対象システム**: SecureZip（macOS ネイティブアプリケーション）
- **作成者**: [作成者名]
- **作成日**: 2026/02/27
- **最終更新日**: 2026/02/27
- **バージョン**: 1.0
- **承認状態**: 作成中

### 1.2 関連文書
| 文書名 | バージョン | 参照目的 | 場所 |
|--------|------------|----------|------|
| 要件定義書 | 1.0 | 機能要件・非機能要件の参照 | requirements_definition.md |
| プロダクト概要ドキュメント | 1.0 | プロジェクト方針・機能仕様の参照 | product-overview.md |

### 1.3 改版履歴
| バージョン | 更新日 | 更新者 | 更新内容 | 承認者 |
|------------|--------|--------|----------|--------|
| 1.0 | 2026/02/27 | [作成者名] | 初版作成 | [承認者名] |

---

## 2. 技術概要

### 2.1 システム概要

SecureZip for Macは、コマンドライン知識不要でビジネスレベルのセキュアなファイル送付を実現するmacOSネイティブアプリケーションである。暗号化圧縮、パスワード管理、Gmail連携送信までをGUI操作のみで一気通貫に完結する。すべてのデータ処理はローカル（App Sandbox内）で完結し、クラウドへの依存を排除している。

### 2.2 技術方針

- **macOSネイティブ**: Swift / SwiftUIによるネイティブ開発。macOS 13 Ventura以降をサポート対象とする
- **システムライブラリ優先**: 圧縮処理にはmacOS標準搭載のlibarchive、暗号処理にはCryptoKitを使用し、外部依存を最小化する
- **ローカル完結**: ユーザーデータはApp Sandbox内のCore DataおよびKeychain Servicesに保存。クラウドストレージは使用しない
- **最小権限の原則**: App Sandbox Entitlementsおよび Gmail APIスコープは必要最小限に限定する
- **SPM統一**: パッケージ管理はSwift Package Managerのみ。CocoaPods / Carthageは使用しない

### 2.3 アーキテクチャ概要

```
┌─────────────────────────────────────────────┐
│          Presentation Layer (SwiftUI)       │
│   メインウィンドウ / 設定画面 / 送信画面      │
├─────────────────────────────────────────────┤
│          ViewModel Layer                     │
│   各画面のViewModel（ObservableObject）       │
├─────────────────────────────────────────────┤
│          Service Layer                       │
│   CompressionService / CryptoService /       │
│   GmailService / HistoryService              │
├─────────────────────────────────────────────┤
│          Data Access Layer                   │
│   Core Data / Keychain Services              │
├─────────────────────────────────────────────┤
│          Infrastructure Layer                │
│   libarchive / CryptoKit / Gmail API /       │
│   FileManager / App Sandbox                  │
└─────────────────────────────────────────────┘
```

### 2.4 技術スタック
| 分野 | 技術・ツール | バージョン | 選択理由 |
|------|--------------|------------|----------|
| 開発言語 | Swift | 5.9+ | Apple公式言語。SwiftUIとの親和性が高い |
| UIフレームワーク | SwiftUI | macOS 13+ | 宣言的UIで開発効率が高い。macOS 13以降のAPIをフル活用 |
| 圧縮エンジン | libarchive | macOS標準搭載 | ZIP / TAR系の圧縮・解凍・AES-256暗号化に対応。追加バンドル不要 |
| 暗号化ライブラリ | CryptoKit | macOS標準搭載 | パスワード生成（SecRandomCopyBytes）、公開鍵暗号（Curve25519）に対応 |
| メール送信 | Gmail API | v1 | OAuth2.0によるバックグラウンド送信。スコープをgmail.sendに限定可能 |
| OAuth認証 | Google Sign-In SDK | 最新安定版 | macOS対応のGoogle公式OAuth SDKa |
| トークン管理 | GTMAppAuth | 最新安定版 | Google Sign-Inと連携したトークンリフレッシュ管理 |
| ローカルDB | Core Data | macOS標準搭載 | 送付履歴・送付先リストの永続化 |
| シークレット管理 | Keychain Services | macOS標準搭載 | トークン・パスワードのセキュアな保管 |
| パッケージ管理 | Swift Package Manager | Xcode付属 | Apple推奨。外部ツール不要 |

---

## 3. 開発環境

### 3.1 開発環境仕様

#### 3.1.1 推奨開発環境
| 項目 | 仕様 | 備考 |
|------|------|------|
| OS | macOS 14 Sonoma 以降 | macOS 13向けビルドが可能 |
| IDE | Xcode 15.0+ | Swift 5.9 / SwiftUI macOS 13+ 対応 |
| CPU | Apple Silicon または Intel | Universal Binary対応 |
| メモリ | 16GB以上 | Xcode + シミュレータ同時実行を考慮 |
| ストレージ | 50GB以上の空き容量 | Xcode + 派生データ |

#### 3.1.2 必須ソフトウェア
| ソフトウェア | バージョン | インストール方法 | 用途 |
|--------------|------------|------------------|------|
| Xcode | 15.0+ | Mac App Store | ビルド・デバッグ・テスト |
| Command Line Tools | Xcode付属 | `xcode-select --install` | コマンドラインビルド |
| Git | 2.39+ | Xcode付属 or Homebrew | バージョン管理 |

#### 3.1.3 開発環境構築手順
```bash
# 1. Xcode Command Line Toolsのインストール
xcode-select --install

# 2. リポジトリのクローン
git clone [リポジトリURL]
cd SecureZip

# 3. Xcodeでプロジェクトを開く（SPM依存は自動解決）
open SecureZip.xcodeproj

# 4. Google Cloud Console設定
#    - プロジェクト作成
#    - Gmail API 有効化
#    - OAuth 2.0 クライアントID作成（macOSアプリ用）
#    - GoogleService-Info.plist を プロジェクトルートに配置

# 5. ビルド & 実行
# Xcode > Product > Run (⌘R)
```

### 3.2 実行環境

#### 3.2.1 対象環境
| 環境種別 | OS/プラットフォーム | バージョン | 備考 |
|----------|---------------------|------------|------|
| 本番環境（ユーザー端末） | macOS | 13 Ventura 以降 | App Store配布 |
| 開発環境 | macOS | 14 Sonoma 以降 | Xcode 15+ |
| テスト環境 | macOS | 13 Ventura 以降 | 最小サポートバージョンでの動作確認 |

#### 3.2.2 システム要件
- **最小システム要件**: macOS 13 Ventura / Apple Silicon または Intel Mac / メモリ 4GB / ストレージ 100MB
- **推奨システム要件**: macOS 14 Sonoma以降 / Apple Silicon Mac / メモリ 8GB

---

## 4. システム設計

### 4.1 アーキテクチャ設計

#### 4.1.1 アーキテクチャパターン

MVVM（Model-View-ViewModel）パターンを採用する。SwiftUIの`@Observable`/`ObservableObject`プロトコルとの相性が良く、UIとビジネスロジックの分離が容易となる。Service層をViewModelの下に配置し、ドメインロジックの再利用性を確保する。

#### 4.1.2 レイヤー構成
| レイヤー名 | 責任 | 主要コンポーネント | 依存関係 |
|------------|------|-------------------|----------|
| View | UI表示・ユーザー入力 | SwiftUI View群 | ViewModel |
| ViewModel | 画面状態管理・UIロジック | MainViewModel, SendViewModel, SettingsViewModel, HistoryViewModel | Service |
| Service | ビジネスロジック・外部連携 | CompressionService, CryptoService, GmailService, HistoryService, KeychainService | Model / Infrastructure |
| Model | データ構造定義 | Core Data Entities, DTO | なし |
| Infrastructure | OS API・外部ライブラリラッパー | LibArchiveWrapper, CryptoKitWrapper, GmailAPIClient | なし |

#### 4.1.3 コンポーネント構成図
```
┌── View ─────────────────────────────────────┐
│  MainView  │  CompressView  │  SendView     │
│  HistoryView  │  SettingsView               │
└──────────────────┬──────────────────────────┘
                   │ @StateObject / @ObservedObject
┌── ViewModel ─────┴──────────────────────────┐
│  MainViewModel    │  CompressViewModel       │
│  SendViewModel    │  HistoryViewModel        │
│  SettingsViewModel                           │
└──────────────────┬──────────────────────────┘
                   │ Dependency Injection
┌── Service ───────┴──────────────────────────┐
│  CompressionService  │  CryptoService        │
│  GmailService        │  HistoryService       │
│  KeychainService     │  FileManagementService│
│  PasswordService     │  AutoDeleteService    │
└──────────────────┬──────────────────────────┘
                   │
┌── Infrastructure ┴──────────────────────────┐
│  LibArchiveWrapper   │  CryptoKitWrapper     │
│  GmailAPIClient      │  CoreDataStack        │
│  KeychainWrapper     │  FileManager          │
└─────────────────────────────────────────────┘
```

### 4.2 データ設計

#### 4.2.1 データモデル設計

Core Dataを使用し、送付履歴と送付先情報を管理する。アプリ設定はUserDefaultsで管理する。パスワード・トークンなどの機密情報はCore DataおよびUserDefaultsに保存せず、Keychain Servicesに保管する。

```
Core Data Model
├── SendHistory（送付履歴）
└── Recipient（送付先）

UserDefaults
└── アプリ設定（キャンセル秒数・パスワード生成設定・自動削除設定等）

Keychain Services
├── Gmail OAuth Access Token
├── Gmail OAuth Refresh Token
└── 暗号化パスワード（履歴IDと紐付け）
```

#### 4.2.2 エンティティ関係図
```
┌─────────────┐       1:N       ┌─────────────┐
│  Recipient  │◄────────────────│ SendHistory  │
│             │                 │             │
│ id (UUID)   │                 │ id (UUID)    │
│ email       │                 │ recipientId  │
│ name        │                 │ fileName     │
│ createdAt   │                 │ fileSize     │
│ updatedAt   │                 │ format       │
└─────────────┘                 │ isEncrypted  │
                                │ sentAt       │
                                │ expiresAt    │
                                │ status       │
                                │ createdAt    │
                                └─────────────┘

```

#### 4.2.3 データ詳細仕様

##### SendHistory（送付履歴）
| カラム名 | データ型 | 必須 | デフォルト値 | 制約 | 説明 |
|----------|----------|------|--------------|------|------|
| id | UUID | ○ | UUID() | Primary Key | 一意識別子 |
| recipientId | UUID | ○ | - | Foreign Key → Recipient.id | 送付先ID |
| fileName | String | ○ | - | - | 圧縮ファイル名 |
| originalFileNames | String | ○ | - | - | 元ファイル名（JSON配列文字列） |
| fileSize | Int64 | ○ | 0 | - | ファイルサイズ（bytes） |
| format | String | ○ | "zip" | - | 圧縮形式（zip / tar.gz / tar.bz2 / tar.zst） |
| isEncrypted | Bool | ○ | false | - | AES-256暗号化の有無 |
| sentAt | Date | × | nil | - | 送信日時（未送信の場合nil） |
| expiresAt | Date | × | nil | - | 自動削除予定日時 |
| status | String | ○ | "created" | - | ステータス（created / sending / sent / cancelled / failed） |
| createdAt | Date | ○ | Date() | - | 作成日時 |

##### Recipient（送付先）
| カラム名 | データ型 | 必須 | デフォルト値 | 制約 | 説明 |
|----------|----------|------|--------------|------|------|
| id | UUID | ○ | UUID() | Primary Key | 一意識別子 |
| email | String | ○ | - | メールアドレス形式 | 送信先メールアドレス |
| name | String | × | nil | - | 表示名 |
| createdAt | Date | ○ | Date() | - | 作成日時 |
| updatedAt | Date | ○ | Date() | - | 更新日時 |

#### 4.2.4 インデックス設計
| テーブル名 | インデックス名 | カラム | 種類 | 目的 |
|------------|----------------|--------|------|------|
| SendHistory | idx_history_sentAt | sentAt | INDEX | 送信日時による履歴検索の高速化 |
| SendHistory | idx_history_expiresAt | expiresAt | INDEX | 自動削除対象の効率的な取得 |
| SendHistory | idx_history_recipientId | recipientId | INDEX | 送付先別履歴検索 |
| Recipient | idx_recipient_email | email | UNIQUE | メールアドレスの一意性保証・検索高速化 |

### 4.3 API設計

#### 4.3.1 外部API利用一覧
| API名 | メソッド | エンドポイント | 機能概要 | 認証 |
|-------|----------|----------------|----------|------|
| Gmail Send | POST | `https://gmail.googleapis.com/gmail/v1/users/me/messages/send` | メール送信 | OAuth 2.0 Bearer Token |
| Google OAuth Token | POST | `https://oauth2.googleapis.com/token` | トークンリフレッシュ | Client ID / Secret |

#### 4.3.2 Gmail API送信仕様
- **エンドポイント**: `POST /gmail/v1/users/me/messages/send`
- **概要**: MIME形式のメールメッセージをBase64URLエンコードして送信
- **認証**: OAuth 2.0 Bearer Token（スコープ: `gmail.send`のみ）
- **リクエスト**:
  ```json
  {
    "raw": "[Base64URLエンコードされたMIMEメッセージ]"
  }
  ```
- **レスポンス（成功）**:
  ```json
  {
    "id": "メッセージID",
    "threadId": "スレッドID",
    "labelIds": ["SENT"]
  }
  ```
- **エラーレスポンス**:
  ```json
  {
    "error": {
      "code": 401,
      "message": "Request had invalid authentication credentials.",
      "status": "UNAUTHENTICATED"
    }
  }
  ```
- **添付ファイルサイズ上限**: 25MB（Gmail API制限）
- **送信レート制限**: 日次送信数上限あり（Google APIクォータに準拠）

### 4.4 UI/UX設計

#### 4.4.1 画面構成
```
SecureZip メインウィンドウ
├── サイドバー（NavigationSplitView）
│   ├── 圧縮
│   ├── 解凍
│   ├── 送信
│   ├── 履歴
│   └── 設定
└── コンテンツ領域
    └── 選択された機能の画面を表示
```

#### 4.4.2 画面一覧
| 画面ID | 画面名 | 概要 | 遷移元 | 遷移先 |
|--------|--------|------|--------|--------|
| SCR-001 | メイン画面 | サイドバー + コンテンツ領域のメインウィンドウ | アプリ起動 | 各機能画面 |
| SCR-002 | 圧縮画面 | ファイル選択・形式選択・暗号化設定・圧縮実行 | サイドバー | 送信画面 / 履歴画面 |
| SCR-003 | 解凍画面 | 圧縮ファイル選択・パスワード入力・解凍実行 | サイドバー | なし |
| SCR-004 | 送信画面 | 送付先入力・ファイル添付・送信実行・キャンセル | サイドバー / 圧縮画面 | 履歴画面 |
| SCR-005 | 履歴画面 | 送付履歴の一覧・検索・詳細表示 | サイドバー | なし |
| SCR-006 | 設定画面 | Gmail連携・パスワード強度・自動削除・キャンセル秒数設定 | サイドバー | OAuth認証画面（Safari） |
| SCR-007 | パスワード生成シート | パスワード強度設定・生成・コピー | 圧縮画面 | なし |
| SCR-008 | 送信キャンセルオーバーレイ | カウントダウン表示・キャンセルボタン | 送信画面 | なし |

#### 4.4.3 画面詳細仕様

##### SCR-002: 圧縮画面
- **概要**: ファイル/フォルダを選択し、圧縮形式・暗号化オプションを指定して圧縮を実行する
- **レイアウト**: ドラッグ&ドロップ領域 + オプション設定パネル + 実行ボタン
- **表示項目**: 選択ファイル一覧、圧縮形式選択（ZIP / TAR.GZ / TAR.BZ2 / TAR.ZST）、AES-256暗号化トグル、パスワード入力欄 / 自動生成ボタン、圧縮先パス
- **操作**: ファイルのドラッグ&ドロップまたはファイル選択ダイアログ（NSOpenPanel）、圧縮実行、圧縮後に送信画面への遷移（任意）
- **バリデーション**: ファイル未選択時は圧縮ボタン無効化、暗号化ON時にパスワード未入力の場合はエラー表示、圧縮先パスの書き込み権限チェック

##### SCR-004: 送信画面
- **概要**: 圧縮済みファイルを選択し、Gmail経由で送信する。パスワード別送信に対応
- **レイアウト**: 送付先入力（オートコンプリート付き） + ファイル選択 + 件名・本文 + パスワード別送信トグル + 送信ボタン
- **操作**: 送信実行 → キャンセルオーバーレイ表示 → カウントダウン後に自動送信 or キャンセル
- **バリデーション**: Gmail未連携時は連携誘導表示、送付先メールアドレス形式チェック、添付ファイル25MB上限チェック

---

## 5. 実装仕様

### 5.1 プログラム構成

#### 5.1.1 ディレクトリ構成
```
SecureZip/
├── SecureZip.xcodeproj
├── SecureZip/
│   ├── App/
│   │   ├── SecureZipApp.swift          - アプリエントリーポイント
│   │   └── AppDelegate.swift           - URLスキームコールバック処理
│   ├── Views/
│   │   ├── MainView.swift              - メインウィンドウ（NavigationSplitView）
│   │   ├── CompressView.swift          - 圧縮画面
│   │   ├── DecompressView.swift        - 解凍画面
│   │   ├── SendView.swift              - 送信画面
│   │   ├── HistoryView.swift           - 履歴画面
│   │   ├── SettingsView.swift          - 設定画面
│   │   └── Components/                 - 共通UIコンポーネント
│   │       ├── DropZoneView.swift      - ドラッグ&ドロップ領域
│   │       ├── PasswordGeneratorSheet.swift - パスワード生成シート
│   │       └── CancelOverlayView.swift - 送信キャンセルオーバーレイ
│   ├── ViewModels/
│   │   ├── CompressViewModel.swift
│   │   ├── DecompressViewModel.swift
│   │   ├── SendViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Services/
│   │   ├── CompressionService.swift    - 圧縮・解凍ビジネスロジック
│   │   ├── CryptoService.swift         - パスワード生成・公開鍵暗号
│   │   ├── GmailService.swift          - Gmail送信・認証管理
│   │   ├── HistoryService.swift        - 送付履歴CRUD
│   │   ├── KeychainService.swift       - Keychain操作ラッパー
│   │   ├── PasswordService.swift       - パスワード生成・強度判定
│   │   ├── AutoDeleteService.swift     - 自動削除スケジュール管理
│   │   └── FileManagementService.swift - 元ファイルの扱い制御
│   ├── Infrastructure/
│   │   ├── LibArchiveWrapper.swift     - libarchive C API ラッパー
│   │   ├── CryptoKitWrapper.swift      - CryptoKit ラッパー
│   │   ├── GmailAPIClient.swift        - Gmail REST API クライアント
│   │   ├── CoreDataStack.swift         - Core Data スタック管理
│   │   └── KeychainWrapper.swift       - Keychain Services ラッパー
│   ├── Models/
│   │   ├── SecureZip.xcdatamodeld      - Core Data モデル定義
│   │   ├── CompressionFormat.swift     - 圧縮形式 enum
│   │   ├── PasswordStrength.swift      - パスワード強度 enum
│   │   └── SendStatus.swift            - 送信ステータス enum
│   ├── Extensions/
│   │   ├── Data+Extensions.swift
│   │   ├── String+Extensions.swift
│   │   └── URL+Extensions.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Localizable.strings
│   │   └── GoogleService-Info.plist
│   └── SecureZip.entitlements
├── SecureZipTests/
│   ├── Services/
│   │   ├── CompressionServiceTests.swift
│   │   ├── CryptoServiceTests.swift
│   │   ├── PasswordServiceTests.swift
│   │   └── HistoryServiceTests.swift
│   └── ViewModels/
│       ├── CompressViewModelTests.swift
│       └── SendViewModelTests.swift
├── SecureZipUITests/
│   ├── CompressionFlowTests.swift
│   └── SendFlowTests.swift
└── Package.swift (SPM依存定義)
```

#### 5.1.2 モジュール構成
| モジュール名 | 責任 | 主要クラス/関数 | 依存関係 |
|--------------|------|----------------|----------|
| App | アプリ起動・ライフサイクル管理 | SecureZipApp, AppDelegate | Views, Services |
| Views | UI表示・ユーザー入力処理 | *View.swift | ViewModels |
| ViewModels | 画面状態管理・UIロジック | *ViewModel.swift | Services |
| Services | ビジネスロジック | *Service.swift | Infrastructure, Models |
| Infrastructure | OS API / 外部APIラッパー | *Wrapper.swift, *Client.swift | システムライブラリ |
| Models | データ構造定義 | Core Data Entities, Enums | なし |

### 5.2 主要クラス/コンポーネント設計

#### 5.2.1 CompressionService
```swift
/// 圧縮・解凍処理を統括するサービス
class CompressionService {
    private let archiveWrapper: LibArchiveWrapper
    private let fileManager: FileManager

    /// ファイル/フォルダを指定形式で圧縮する
    /// - Parameters:
    ///   - sources: 圧縮対象のファイル/フォルダURLの配列
    ///   - destination: 出力先URL
    ///   - format: 圧縮形式（.zip / .tarGz / .tarBz2 / .tarZst）
    ///   - password: AES-256暗号化パスワード（nilの場合は暗号化なし、ZIP形式のみ有効）
    ///   - progress: 進捗コールバック (0.0 ~ 1.0)
    func compress(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        progress: @escaping (Double) -> Void
    ) async throws

    /// 圧縮ファイルを解凍する
    func decompress(
        source: URL,
        destination: URL,
        password: String?,
        progress: @escaping (Double) -> Void
    ) async throws

    /// ファイルを指定サイズで分割圧縮する
    func compressWithSplit(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        splitSizeBytes: Int64,
        progress: @escaping (Double) -> Void
    ) async throws -> [URL]
}
```

- **責任**: 圧縮・解凍処理のオーケストレーション
- **依存関係**: LibArchiveWrapper, FileManager

#### 5.2.2 GmailService
```swift
/// Gmail API連携によるメール送信サービス
class GmailService {
    private let apiClient: GmailAPIClient
    private let keychainService: KeychainService

    /// Gmail OAuth認証を開始する
    func authenticate() async throws

    /// 認証状態を確認する
    var isAuthenticated: Bool { get }

    /// 暗号化ファイルとパスワードを別メールで送信する
    /// - Returns: キャンセル可能なTask
    func sendWithSeparatePassword(
        file: URL,
        password: String,
        recipient: String,
        subject: String,
        body: String
    ) async throws -> Task<Void, Error>

    /// Gmail連携を解除する
    func disconnect() async throws
}
```

- **責任**: Gmail OAuth認証管理・メール送信・送信キャンセル
- **依存関係**: GmailAPIClient, KeychainService, GTMAppAuth

#### 5.2.3 PasswordService
```swift
/// パスワード生成・強度評価サービス
class PasswordService {
    private let cryptoWrapper: CryptoKitWrapper

    /// ランダムパスワードを生成する
    func generatePassword(
        length: Int,
        includeUppercase: Bool,
        includeLowercase: Bool,
        includeNumbers: Bool,
        includeSymbols: Bool
    ) -> String

    /// パスワード強度を評価する
    func evaluateStrength(_ password: String) -> PasswordStrength
}
```

- **責任**: 暗号学的に安全なパスワード生成。SecRandomCopyBytesを使用
- **依存関係**: CryptoKitWrapper

### 5.3 データアクセス層

#### 5.3.1 データアクセスパターン

Repositoryパターンを採用する。Core Dataの`NSManagedObjectContext`への直接アクセスをService層に対して隠蔽し、テスタビリティを確保する。

#### 5.3.2 データアクセス実装
```swift
/// 送付履歴のリポジトリ
protocol SendHistoryRepositoryProtocol {
    func fetchAll() async throws -> [SendHistory]
    func fetch(by id: UUID) async throws -> SendHistory?
    func fetchExpired(before date: Date) async throws -> [SendHistory]
    func save(_ history: SendHistory) async throws
    func delete(_ history: SendHistory) async throws
    func deleteAll(ids: [UUID]) async throws
}

class SendHistoryRepository: SendHistoryRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    func fetchExpired(before date: Date) async throws -> [SendHistory] {
        let request = SendHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "expiresAt != nil AND expiresAt < %@",
            date as NSDate
        )
        // Core Data バックグラウンドコンテキストで実行
        return try await coreDataStack.performBackground { context in
            try context.fetch(request).map { $0.toDomain() }
        }
    }
}
```

### 5.4 ビジネスロジック層

#### 5.4.1 ビジネスルール

- 暗号化圧縮はZIP形式のみ対応。TAR系形式で暗号化が要求された場合はエラーを返す
- パスワード自動生成のデフォルトは16文字（大文字・小文字・数字・記号を含む）
- 送信キャンセルは、ユーザー設定の秒数（デフォルト5秒）以内のみ有効。カウントダウン終了後はGmail APIを呼び出す
- 自動削除は`expiresAt`に設定された日時を過ぎた履歴をTimer/バックグラウンド復帰時に削除
- パスワード別送信時、本体メールとパスワード通知メールは数秒の間隔をあけて送信する
- 添付ファイルが25MBを超える場合は分割圧縮を推奨するアラートを表示

#### 5.4.2 送信フロー
```
1. ユーザーが送信ボタンを押下
2. バリデーション実行（送付先・添付ファイル・Gmail認証状態）
3. カウントダウンオーバーレイを表示（Swift Concurrency Task開始）
4. カウントダウン中：
   a. キャンセルボタン押下 → Task.cancel() で即時中断
   b. カウントダウン終了 → 以下を実行
5. MIMEメッセージ構築（添付ファイルBase64エンコード）
6. Gmail API呼び出し（本体メール送信）
7. パスワード別送信ONの場合：
   a. 数秒待機
   b. パスワード通知メール送信
8. 送付履歴をCore Dataに保存
9. パスワードをKeychainに保存（履歴IDと紐付け）
10. 完了通知をUIに表示
```

---

## 6. セキュリティ仕様

### 6.1 セキュリティ要件
| セキュリティ要素 | 実装方法 | 対象範囲 | 備考 |
|------------------|----------|----------|------|
| ファイル暗号化 | AES-256（libarchive） | ZIP圧縮ファイル | WinZip互換のAES暗号化 |
| パスワード保管 | Keychain Services | パスワード・OAuthトークン | App Sandbox内でアプリ固有 |
| 公開鍵暗号 | Curve25519（CryptoKit） | パスワードの保管・送信 | 将来フェーズ（Phase 4）で実装 |
| OAuth認証 | OAuth 2.0 + PKCE | Gmail API連携 | スコープはgmail.sendのみ |
| アプリ分離 | App Sandbox | アプリ全体 | ファイルアクセスはユーザー選択分のみ |
| 入力検証 | SwiftUI Validation | 全入力フォーム | メールアドレス形式・パスワード要件等 |

### 6.2 認証・認可設計

#### 6.2.1 OAuth 2.0認証フロー
```
┌──────────┐     1. 認証要求      ┌──────────────┐
│ SecureZip │ ──────────────────► │ Google OAuth  │
│   App     │                     │   Server      │
│           │ ◄────────────────── │               │
│           │  2. 認証コード       │               │
│           │     (URL Scheme)    │               │
│           │                     │               │
│           │  3. トークン交換     │               │
│           │ ──────────────────► │               │
│           │                     │               │
│           │ ◄────────────────── │               │
│           │  4. Access Token    │               │
│           │     + Refresh Token │               │
└──────────┘                     └──────────────┘
      │
      │ 5. Keychainに保存
      ▼
┌──────────┐
│ Keychain │
│ Services │
└──────────┘
```

- Google Sign-In SDK + GTMAppAuthを使用
- カスタムURLスキーム（例: `com.securezip.callback://`）でコールバックを受信
- スコープは `https://www.googleapis.com/auth/gmail.send` のみに限定
- アクセストークン期限切れ時はGTMAppAuthがRefresh Tokenで自動更新

#### 6.2.2 Keychain保存設計
```swift
// Keychainに保存するデータのキー定義
enum KeychainKey {
    static let passwordPrefix = "com.tkrite.SecureZip.password."  // + historyID
}

// Keychainアクセス属性
// - kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
// - kSecAttrSynchronizable: false（iCloud Keychainには同期しない）
```

### 6.3 データ保護

#### 6.3.1 暗号化実装
```swift
// AES-256暗号化圧縮（libarchive経由）
// LibArchiveWrapperでの設定
func setEncryption(archive: OpaquePointer, password: String) {
    archive_write_set_options(archive, "zip:encryption=aes256")
    archive_write_set_passphrase(archive, password)
}
```

#### 6.3.2 パスワード生成
```swift
// 暗号学的に安全な乱数によるパスワード生成
func generateSecurePassword(length: Int, charset: String) -> String {
    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    guard status == errSecSuccess else { fatalError("SecRandomCopyBytes failed") }
    return bytes.map { charset[charset.index(charset.startIndex, offsetBy: Int($0) % charset.count)] }
        .map(String.init).joined()
}
```

### 6.4 Sandbox Entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox有効化 -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- ネットワーク送信（Gmail API用） -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- ファイルアクセス（ユーザーが選択したファイルのみ） -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>

    <!-- ダウンロードフォルダへの書き込み（解凍先デフォルト） -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

---

## 7. パフォーマンス仕様

### 7.1 パフォーマンス要件
| 項目 | 目標値 | 測定条件 | 実装方針 |
|------|--------|----------|----------|
| 圧縮速度 | 100MB/s以上 | ZIP形式・暗号化なし・SSD環境 | libarchiveネイティブ性能に依存。ストリーミング処理 |
| 暗号化圧縮速度 | 50MB/s以上 | ZIP AES-256・SSD環境 | libarchiveのAES実装を使用 |
| UI応答性 | 16ms以内（60fps） | 圧縮処理中のUI操作 | 重い処理はすべてバックグラウンドスレッドで実行 |
| アプリ起動時間 | 2秒以内 | コールドスタート | 遅延読み込み。Core Data初期化は非同期 |
| メモリ使用量 | 200MB以下 | 1GB圧縮処理中 | ストリーミング処理でメモリ使用を最小化 |

### 7.2 最適化実装

#### 7.2.1 圧縮処理の非同期化
```swift
// Swift Concurrencyによるバックグラウンド圧縮
func compress(...) async throws {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            // libarchiveによるストリーミング圧縮
            // 大容量ファイルでもメモリ使用量を一定に保つ
        }
    }
}
```

#### 7.2.2 進捗表示の最適化
- 圧縮進捗は`@MainActor`でUIに反映。更新頻度は最大30fps（33ms間隔）に制限し、UI負荷を軽減する

---

## 8. エラーハンドリング仕様

### 8.1 エラー分類
| エラー分類 | エラーコード範囲 | 対応方法 | ログレベル |
|------------|------------------|----------|------------|
| 圧縮エラー | COMP-001 ~ 099 | ユーザーにアラート表示。リトライ可能 | ERROR |
| 暗号化エラー | CRYPT-001 ~ 099 | ユーザーにアラート表示 | ERROR |
| 送信エラー | SEND-001 ~ 099 | リトライボタン表示。ネットワーク状態確認 | ERROR |
| 認証エラー | AUTH-001 ~ 099 | 再認証フロー誘導 | WARN |
| ファイルアクセスエラー | FILE-001 ~ 099 | 権限要求またはファイル再選択 | WARN |
| データ保存エラー | DATA-001 ~ 099 | ユーザーに通知。データ整合性チェック | ERROR |
| バリデーションエラー | VALID-001 ~ 099 | インライン表示 | INFO |

### 8.2 エラーハンドリング実装
```swift
/// アプリ共通エラー型
enum SecureZipError: LocalizedError {
    case compressionFailed(underlying: Error)
    case encryptionNotSupported(format: CompressionFormat)
    case passwordTooWeak
    case gmailNotAuthenticated
    case gmailSendFailed(statusCode: Int, message: String)
    case fileTooLarge(size: Int64, limit: Int64)
    case fileAccessDenied(url: URL)
    case keychainError(status: OSStatus)
    case coreDataError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .encryptionNotSupported(let format):
            return "暗号化は\(format.displayName)形式では利用できません。ZIP形式を選択してください。"
        case .gmailNotAuthenticated:
            return "Gmailと連携されていません。設定画面から連携してください。"
        case .fileTooLarge(let size, let limit):
            return "ファイルサイズ(\(size.formatted))が上限(\(limit.formatted))を超えています。"
        // ...
        }
    }
}
```

### 8.3 ログ設計

#### 8.3.1 ログレベル定義
| レベル | 出力条件 | 出力内容 | 保存先 |
|--------|----------|----------|--------|
| ERROR | 処理失敗・例外発生 | エラー内容・スタックトレース・コンテキスト | os_log (Unified Logging) |
| WARN | 想定外だが回復可能な状態 | 警告内容・コンテキスト | os_log |
| INFO | 主要操作の実行記録 | 操作内容（圧縮完了・送信完了等） | os_log |
| DEBUG | デバッグ用詳細情報 | 処理パラメータ・中間状態 | os_log（DEBUG時のみ） |

- ログにパスワード・トークン等の機密情報は絶対に出力しない
- Unified Logging（os_log）を使用し、Console.appおよび`log`コマンドで確認可能とする

---

## 9. テスト仕様

### 9.1 テスト戦略

テストピラミッドに基づき、単体テスト > 統合テスト > UIテストの優先度で実装する。Service層のプロトコル化によりモック差し替えを容易にし、テスタビリティを確保する。

### 9.2 テスト種別

#### 9.2.1 単体テスト
- **対象**: Service層・ViewModel層・ユーティリティ
- **ツール**: XCTest
- **カバレッジ目標**: Service層 80%以上、ViewModel層 70%以上
- **重点テスト項目**:
  - CompressionService: 各形式の圧縮・解凍、暗号化の正常系・異常系
  - PasswordService: パスワード生成のランダム性・強度評価
  - HistoryService: CRUD操作・自動削除ロジック
  - SendViewModel: 送信フロー・キャンセル処理

#### 9.2.2 統合テスト
- **対象**: Core Data ↔ Service連携、Keychain ↔ Service連携
- **ツール**: XCTest + インメモリCore Dataストア
- **テストケース例**: 圧縮 → 履歴保存 → パスワードKeychain保存 → 履歴取得時にパスワード復元

#### 9.2.3 UIテスト
- **対象**: 主要ユーザーフロー
- **ツール**: XCUITest
- **シナリオ例**: ファイルドロップ → 圧縮形式選択 → 暗号化ON → パスワード生成 → 圧縮実行 → 完了確認

### 9.3 テスト環境
| 環境名 | 用途 | 構成 | データ |
|--------|------|------|--------|
| ローカルテスト | 開発者の日常テスト | Xcode + macOS 14 | インメモリCore Data |
| CI | 自動テスト | GitHub Actions / Xcode Cloud | テスト用フィクスチャ |
| 手動テスト | macOS 13互換確認 | macOS 13 Ventura実機 or VM | テスト用サンプルファイル |

---

## 10. 運用仕様

### 10.1 デプロイメント

#### 10.1.1 デプロイ戦略
App Store経由の配布を行う。Xcode Cloud または手動によるArchive → App Store Connect アップロード → 審査 → リリースのフローとする。

#### 10.1.2 App Store申請チェックリスト
```
□ App Sandbox有効化確認
□ 全Entitlementsの妥当性確認
□ プライバシーポリシーURL設定
□ App Review Notes記載（Gmail連携理由）
□ テスト用Googleアカウント情報準備
□ スクリーンショット準備（各解像度）
□ アプリ説明文（日本語・英語）
□ カテゴリ設定（ユーティリティ）
□ 年齢レーティング設定
```

#### 10.1.3 バージョニング
- Semantic Versioning（MAJOR.MINOR.PATCH）を採用
- App Store Build Numberは自動インクリメント

---

## 11. 外部連携仕様

### 11.1 外部システム連携

#### 11.1.1 連携システム一覧
| システム名 | 連携方法 | データ形式 | 認証方式 | 備考 |
|------------|----------|------------|----------|------|
| Gmail API | REST API (HTTPS) | JSON + Base64 MIME | OAuth 2.0 | スコープ: gmail.send のみ |
| Google OAuth Server | OAuth 2.0 + PKCE | JSON | Client ID | カスタムURLスキームでコールバック |
| macOS Keychain | Keychain Services API | バイナリ | App Sandbox | デバイスローカルのみ |

### 11.2 サードパーティライブラリ

#### 11.2.1 使用ライブラリ一覧
| ライブラリ名 | バージョン | 用途 | ライセンス | 備考 |
|--------------|------------|------|------------|------|
| GoogleSignIn-iOS | 最新安定版 | OAuth 2.0 認証 | Apache 2.0 | SPM経由 |
| GTMAppAuth | 最新安定版 | OAuthトークン管理 | Apache 2.0 | SPM経由 |

#### 11.2.2 システムライブラリ（バンドル不要）
| ライブラリ名 | 用途 | ライセンス |
|--------------|------|------------|
| libarchive.dylib | 圧縮・解凍・AES-256暗号化 | BSD |
| CryptoKit.framework | パスワード生成・Curve25519公開鍵暗号 | Apple |
| CoreData.framework | ローカルデータ永続化 | Apple |
| Security.framework | Keychain Services | Apple |

#### 11.2.3 ライブラリ更新方針
- 月次でSPMライブラリのセキュリティアップデートを確認
- メジャーバージョンアップはリリース前に互換性テストを実施
- Dependabotまたは手動でバージョン監視

---

## 12. 設定管理

### 12.1 設定ファイル

#### 12.1.1 アプリ設定項目
| 設定キー | データ型 | デフォルト値 | 説明 |
|----------|----------|--------------|------|
| `cancelDelaySeconds` | Int | 5 | 送信キャンセル猶予秒数（1〜10秒） |
| `defaultFormat` | String | "zip" | デフォルト圧縮形式 |
| `passwordLength` | Int | 16 | 自動生成パスワードの文字数 |
| `passwordIncludeUppercase` | Bool | true | パスワードに大文字を含む |
| `passwordIncludeLowercase` | Bool | true | パスワードに小文字を含む |
| `passwordIncludeNumbers` | Bool | true | パスワードに数字を含む |
| `passwordIncludeSymbols` | Bool | true | パスワードに記号を含む |
| `autoDeleteEnabled` | Bool | true | 自動削除の有効/無効 |
| `autoDeleteDays` | Int | 30 | 自動削除までの日数 |
| `separatePasswordEmail` | Bool | true | パスワード別送信のデフォルト |
| `postCompressionAction` | String | "keep" | 圧縮後の元ファイル処理（keep / move / delete） |

#### 12.1.2 設定の保存先
- ユーザー設定: UserDefaults（`settings.*` プレフィックスのキーで管理）
- 機密設定（トークン等）: Keychain Services

### 12.2 シークレット管理
- OAuthトークン（Access Token / Refresh Token）: Keychain Services に `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` で保存
- 送付パスワード: Keychain Services に履歴IDと紐付けて保存
- Google Client ID / Secret: GoogleService-Info.plist に格納（App Bundle内）
- Git管理対象外: `.gitignore`にGoogleService-Info.plistを追加

---

## 13. ドキュメント・コメント規約

### 13.1 コーディング規約
- Appleの[Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)に準拠
- SwiftLintを導入し、一貫したコードスタイルを維持
- `// MARK: -` によるコードセクション分割を推奨

### 13.2 コメント規約
```swift
/// 圧縮ファイルのAES-256暗号化を設定する
///
/// ZIP形式でのみ使用可能。他の形式で呼び出した場合は
/// `SecureZipError.encryptionNotSupported` をスローする。
///
/// - Parameters:
///   - archive: libarchiveのアーカイブポインタ
///   - password: 暗号化パスワード（8文字以上推奨）
/// - Throws: `SecureZipError.encryptionNotSupported` 非対応形式の場合
///           `SecureZipError.compressionFailed` libarchiveエラーの場合
func setEncryption(archive: OpaquePointer, password: String) throws
```

### 13.3 APIドキュメント
- Swift DocC を使用してAPIドキュメントを自動生成
- `Product > Build Documentation` (⌃⇧⌘D) でXcode内プレビュー可能

---

## 14. 付録

### 14.1 用語集
| 用語 | 定義 | 英語 |
|------|------|------|
| AES-256 | Advanced Encryption Standard。256ビット鍵長の共通鍵暗号方式 | AES-256 |
| Curve25519 | 楕円曲線暗号に基づく公開鍵暗号方式 | Curve25519 |
| libarchive | マルチフォーマット対応のアーカイブ・圧縮ライブラリ | libarchive |
| App Sandbox | macOSのアプリ分離セキュリティ機構 | App Sandbox |
| Keychain | macOSのセキュアな認証情報保管システム | Keychain Services |
| OAuth 2.0 | 認可フレームワーク。サードパーティアプリへの限定的なアクセス権付与 | OAuth 2.0 |
| SPM | Swift Package Manager。Swift公式のパッケージ管理ツール | Swift Package Manager |
| PKCE | OAuth 2.0のセキュリティ拡張。認可コード横取り攻撃を防止 | Proof Key for Code Exchange |
| MIME | メールメッセージのフォーマット規格 | Multipurpose Internet Mail Extensions |

### 14.2 参考資料
- [Apple Developer - libarchive](https://developer.apple.com/library/archive/documentation/)
- [Apple Developer - CryptoKit](https://developer.apple.com/documentation/cryptokit)
- [Gmail API リファレンス](https://developers.google.com/gmail/api/reference/rest)
- [Google Sign-In for iOS/macOS](https://developers.google.com/identity/sign-in/ios)
- [Apple Developer - App Sandbox](https://developer.apple.com/documentation/security/app_sandbox)
- [Apple Developer - Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

---

## 15. 承認

### 15.1 レビュー記録
| レビュー日 | レビュアー | レビュー結果 | コメント |
|------------|------------|--------------|----------|
| [YYYY/MM/DD] | [レビュアー名] | [承認/条件付き承認/却下] | [コメント] |

### 15.2 承認記録
| 役割 | 氏名 | 承認日 | 署名 |
|------|------|--------|------|
| アーキテクト | [氏名] | [YYYY/MM/DD] | [署名] |
| テックリード | [氏名] | [YYYY/MM/DD] | [署名] |
| プロジェクトマネージャー | [氏名] | [YYYY/MM/DD] | [署名] |

---

**文書情報**
- 分類: 技術仕様書
- 機密レベル: 社内限り
- 配布先: 開発チーム・プロジェクト関係者
- 次回レビュー予定日: [YYYY/MM/DD]
