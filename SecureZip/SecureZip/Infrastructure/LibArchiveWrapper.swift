import Foundation

// libarchive は macOS 標準搭載。Xcode プロジェクトでは
// "Other Linker Flags" に -larchive を追加し、
// ブリッジングヘッダーに #import <archive.h> / #import <archive_entry.h> を追加してください。

// MARK: - C API シンボル宣言（ブリッジングヘッダー代替）
// Xcode プロジェクト構成後はブリッジングヘッダー経由で提供されるため不要になります。

/// libarchive C API の Swift ラッパー
///
/// ストリーミング処理により大容量ファイルでもメモリ使用量を最小化する。
/// AES-256 暗号化は ZIP 形式のみ対応（zip:encryption=aes256 オプション）。
///
/// **Xcode プロジェクト設定（必須）:**
/// 1. プロジェクト設定 > Build Settings > Other Linker Flags に `-larchive` を追加
/// 2. ブリッジングヘッダー（`SecureZip-Bridging-Header.h`）を作成し以下を記述:
///    ```c
///    #import <archive.h>
///    #import <archive_entry.h>
///    ```
/// 3. Build Settings > Swift Compiler - General > Objective-C Bridging Header に
///    `SecureZip/SecureZip-Bridging-Header.h` を設定
final class LibArchiveWrapper {

    // MARK: - Constants

    private static let blockSize: Int = 65536  // 64KB ストリーミングバッファ

    // MARK: - Compress

    /// ファイル/フォルダを圧縮する（Process ベース実装）
    ///
    /// libarchive C API のブリッジング設定が完了するまでの間は
    /// macOS 標準の `ditto` / `zip` コマンドを使用した Process ベース実装を提供する。
    func compress(
        sources: [URL],
        destination: URL,
        format: CompressionFormat,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        switch format {
        case .zip:
            try await compressZip(
                sources: sources, destination: destination,
                password: password, progress: progress
            )
        case .tarGz:
            try await compressTar(
                sources: sources, destination: destination,
                compressionFlag: "z", progress: progress
            )
        case .tarBz2:
            try await compressTar(
                sources: sources, destination: destination,
                compressionFlag: "j", progress: progress
            )
        case .tarZst:
            try await compressTar(
                sources: sources, destination: destination,
                compressionFlag: "--zstd", progress: progress
            )
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
        let ext = source.pathExtension.lowercased()
        let name = source.deletingPathExtension().pathExtension.lowercased()

        if ext == "zip" {
            try await decompressZip(source: source, destination: destination,
                                    password: password, progress: progress)
        } else if ext == "gz" && name == "tar" {
            try await decompressTar(source: source, destination: destination,
                                    flags: ["xzf"], progress: progress)
        } else if ext == "bz2" && name == "tar" {
            try await decompressTar(source: source, destination: destination,
                                    flags: ["xjf"], progress: progress)
        } else if ext == "zst" && name == "tar" {
            try await decompressTar(source: source, destination: destination,
                                    flags: ["x", "--zstd", "-f"], progress: progress)
        } else {
            // 汎用フォールバック：ditto で試みる
            try await runProcess(
                executable: "/usr/bin/ditto",
                arguments: ["-xk", source.path, destination.path],
                progress: progress
            )
        }
    }

    // MARK: - ZIP

    private func compressZip(
        sources: [URL],
        destination: URL,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        progress(0.1)

        if let password = password, !password.isEmpty {
            // パスワード保護 ZIP（ZipCrypto 暗号化）
            // パスワードは stdin 経由で渡し、プロセス引数リストへの露出を防ぐ
            // AES-256 対応は Phase 2 で libarchive C API により実装予定
            try await compressZipEncrypted(
                sources: sources, destination: destination,
                password: password, progress: progress
            )
        } else {
            // 通常 ZIP
            var args = ["-r", destination.path]
            args += sources.map { $0.path }
            try await runProcess(executable: "/usr/bin/zip", arguments: args, progress: progress)
        }
        progress(1.0)
    }

    private func compressZipEncrypted(
        sources: [URL],
        destination: URL,
        password: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        // /usr/bin/zip -e はパスワード入力を対話的に2回要求するため、
        // "password\npassword\n" を stdin 経由で渡す。
        // コマンドライン引数にパスワードを含めないことで `ps aux` への露出を防ぐ。
        // 暗号化方式: ZipCrypto（AES-256 は Phase 2 で libarchive C API により対応予定）
        var args = ["-r", "-e", destination.path]
        args += sources.map { $0.path }
        let passwordInput = Data("\(password)\n\(password)\n".utf8)
        try await runProcess(
            executable: "/usr/bin/zip",
            arguments: args,
            stdinData: passwordInput,
            progress: progress
        )
    }

    private func decompressZip(
        source: URL,
        destination: URL,
        password: String?,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        progress(0.1)
        var args = [source.path, "-d", destination.path]
        if let pw = password, !pw.isEmpty {
            args = ["-P", pw, source.path, "-d", destination.path]
        }
        try await runProcess(executable: "/usr/bin/unzip", arguments: args, progress: progress)
        progress(1.0)
    }

    // MARK: - TAR

    private func compressTar(
        sources: [URL],
        destination: URL,
        compressionFlag: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        progress(0.1)
        var args: [String]
        if compressionFlag.hasPrefix("--") {
            args = ["-c", compressionFlag, "-f", destination.path]
        } else {
            args = ["-c\(compressionFlag)f", destination.path]
        }
        args += sources.map { $0.path }
        try await runProcess(executable: "/usr/bin/tar", arguments: args, progress: progress)
        progress(1.0)
    }

    private func decompressTar(
        source: URL,
        destination: URL,
        flags: [String],
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        progress(0.1)
        let args = flags + [source.path, "-C", destination.path]
        try await runProcess(executable: "/usr/bin/tar", arguments: args, progress: progress)
        progress(1.0)
    }

    // MARK: - Process Runner

    private func runProcess(
        executable: String,
        arguments: [String],
        stdinData: Data? = nil,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments

                let errorPipe = Pipe()
                process.standardError = errorPipe

                // stdin 経由でデータを渡す場合はプロセス起動前に Pipe をセットする
                let inputPipe: Pipe?
                if stdinData != nil {
                    let pipe = Pipe()
                    process.standardInput = pipe
                    inputPipe = pipe
                } else {
                    inputPipe = nil
                }

                do {
                    try process.run()

                    // プロセス起動後に stdin へ書き込んでクローズする
                    if let data = stdinData, let pipe = inputPipe {
                        pipe.fileHandleForWriting.write(data)
                        pipe.fileHandleForWriting.closeFile()
                    }

                    process.waitUntilExit()

                    if process.terminationStatus == 0 {
                        progress(1.0)
                        continuation.resume()
                    } else {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "不明なエラー"
                        let error = NSError(
                            domain: "LibArchiveWrapper",
                            code: Int(process.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        )
                        continuation.resume(throwing: SecureZipError.compressionFailed(underlying: error))
                    }
                } catch {
                    continuation.resume(throwing: SecureZipError.compressionFailed(underlying: error))
                }
            }
        }
    }
}
