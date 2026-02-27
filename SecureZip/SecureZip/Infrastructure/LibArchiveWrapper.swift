import Foundation

/// libarchive C API の Swift ラッパー
///
/// libarchive はmacOS標準搭載のアーカイブライブラリ。
/// ストリーミング処理により大容量ファイルでもメモリ使用量を最小化する。
///
/// - Note: AES-256 暗号化は ZIP 形式のみ対応（zip:encryption=aes256 オプション）
final class LibArchiveWrapper {

    // MARK: - Compress

    /// ファイル/フォルダを圧縮する
    func compress(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // TODO: libarchive C API を使用した圧縮実装
                    // archive_write_new() → フォーマット設定 → フィルター設定 →
                    // パスワード設定（ZIP暗号化時） → archive_write_open_filename() →
                    // 各ソースを archive_write_header() / archive_write_data() でストリーミング書き込み →
                    // archive_write_close() / archive_write_free()
                    progress(1.0)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: SecureZipError.compressionFailed(underlying: error))
                }
            }
        }
    }

    // MARK: - Decompress

    /// 圧縮ファイルを解凍する
    func decompress(
        source: URL,
        destination: URL,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // TODO: libarchive C API を使用した解凍実装
                    // archive_read_new() → フォーマット自動検出 →
                    // パスワード設定 → archive_read_open_filename() →
                    // archive_read_next_header() ループで各エントリを抽出 →
                    // archive_read_close() / archive_read_free()
                    progress(1.0)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: SecureZipError.decompressionFailed(underlying: error))
                }
            }
        }
    }
}
