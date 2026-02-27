import Foundation

// MARK: - Protocol

protocol CompressionServiceProtocol {
    func compress(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws

    func decompress(
        source: URL,
        destination: URL,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws
}

// MARK: - Implementation

/// 圧縮・解凍処理を統括するサービス
///
/// libarchive を使用してストリーミング圧縮を行う。
/// 大容量ファイルでもメモリ使用量を一定に保つ。
final class CompressionService: CompressionServiceProtocol {

    private let archiveWrapper: LibArchiveWrapper
    private let fileManager: FileManager

    init(archiveWrapper: LibArchiveWrapper = LibArchiveWrapper(),
         fileManager: FileManager = .default) {
        self.archiveWrapper = archiveWrapper
        self.fileManager = fileManager
    }

    /// ファイル/フォルダを指定形式で圧縮する
    func compress(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        // 暗号化は ZIP 形式のみ対応
        if let _ = password, !format.supportsEncryption {
            throw SecureZipError.encryptionNotSupported(format: format)
        }
        // TODO: libarchive を使用したストリーミング圧縮処理を実装
        try await archiveWrapper.compress(
            sources: sources,
            destination: destination,
            format: format,
            password: password,
            progress: progress
        )
    }

    /// 圧縮ファイルを解凍する
    func decompress(
        source: URL,
        destination: URL,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        // TODO: libarchive を使用した解凍処理を実装
        try await archiveWrapper.decompress(
            source: source,
            destination: destination,
            password: password,
            progress: progress
        )
    }
}

// MARK: - Error Types

enum SecureZipError: LocalizedError {
    case encryptionNotSupported(format: CompressionFormat)
    case passwordTooWeak
    case gmailNotAuthenticated
    case gmailSendFailed(statusCode: Int, message: String)
    case fileTooLarge(size: Int64, limit: Int64)
    case fileAccessDenied(url: URL)
    case keychainError(status: OSStatus)
    case coreDataError(underlying: Error)
    case compressionFailed(underlying: Error)
    case decompressionFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .encryptionNotSupported(let format):
            return "暗号化は\(format.displayName)形式では利用できません。ZIP形式を選択してください。"
        case .passwordTooWeak:
            return "パスワードが短すぎます。8文字以上のパスワードを設定してください。"
        case .gmailNotAuthenticated:
            return "Gmailと連携されていません。設定画面から連携してください。"
        case .gmailSendFailed(let code, let msg):
            return "メール送信に失敗しました (HTTP \(code)): \(msg)"
        case .fileTooLarge(let size, let limit):
            return "ファイルサイズ(\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))がGmail上限(\(ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)))を超えています。"
        case .fileAccessDenied(let url):
            return "ファイルへのアクセスが拒否されました: \(url.lastPathComponent)"
        case .keychainError(let status):
            return "Keychainエラーが発生しました (status: \(status))"
        case .coreDataError(let err):
            return "データ保存エラー: \(err.localizedDescription)"
        case .compressionFailed(let err):
            return "圧縮処理に失敗しました: \(err.localizedDescription)"
        case .decompressionFailed(let err):
            return "解凍処理に失敗しました: \(err.localizedDescription)"
        }
    }
}
