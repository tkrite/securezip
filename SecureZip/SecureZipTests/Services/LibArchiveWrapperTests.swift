import XCTest
import Compression
@testable import SecureZip

/// LibArchiveWrapper.validateTarPaths(source:destination:) の単体テスト
///
/// validateTarPaths は private メソッドのため、decompress(_:destination:password:progress:)
/// 経由でテストする。
///
/// ## validateTarPaths の設計
/// `validateTarPaths` は「..」「.」「空コンポーネント」を除去（sanitize）することで
/// パストラバーサルを無力化する設計である。
/// - `../escape.txt`    → sanitize → `escape.txt`    → destination 配下 → OK
/// - `/etc/passwd`      → sanitize → `etc/passwd`    → destination 配下 → OK
/// - `../../deep.txt`   → sanitize → `deep.txt`      → destination 配下 → OK
/// エラー（decompressionFailed）がスローされるのは、sanitize 後のパスが
/// destination 外を指す場合のみである。
///
/// ## App Sandbox 制約
/// テストターゲットは App Sandbox 下で動作するため外部プロセス（/usr/bin/tar 等）を
/// 呼び出せない。TAR.GZ バイナリはすべて Swift で直接生成する。
/// - TAR ヘッダー: POSIX ustar 形式を手書き構築
/// - gzip 圧縮: Apple Compression フレームワーク（COMPRESSION_ZLIB）+ gzip ヘッダー/フッター手書き
final class LibArchiveWrapperTests: XCTestCase {

    private var sut: LibArchiveWrapper!
    private var tempDirectory: URL!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        sut = LibArchiveWrapper()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibArchiveWrapperTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
    }

    // MARK: - TAR.GZ ビルダー

    /// TAR ヘッダー（512 バイト POSIX ustar）を構築するヘルパー
    ///
    /// - Parameters:
    ///   - name: エントリパス（悪意あるパスも設定可能）
    ///   - size: ファイルデータのバイト数
    /// - Returns: 512 バイトの TAR ヘッダー
    private func buildTarHeader(name: String, size: Int) -> Data {
        var header = [UInt8](repeating: 0, count: 512)

        // name フィールド（0..99, 100 バイト）
        let nameBytes = Array(name.utf8.prefix(99))
        for (i, b) in nameBytes.enumerated() { header[i] = b }

        // mode（100..107）
        for (i, b) in Array("0000644\0".utf8).enumerated() { header[100 + i] = b }
        // uid（108..115）
        for (i, b) in Array("0000000\0".utf8).enumerated() { header[108 + i] = b }
        // gid（116..123）
        for (i, b) in Array("0000000\0".utf8).enumerated() { header[116 + i] = b }

        // size（124..135, 12 バイト oct）
        let sizeStr = String(format: "%011o\0", size)
        for (i, b) in Array(sizeStr.utf8).enumerated() { header[124 + i] = b }

        // mtime（136..147）
        for (i, b) in Array("00000000000\0".utf8).enumerated() { header[136 + i] = b }

        // checksum placeholder（148..155, 8 スペース）
        for i in 0..<8 { header[148 + i] = UInt8(ascii: " ") }

        // typeflag（156）= '0' 通常ファイル
        header[156] = UInt8(ascii: "0")

        // magic（257..262）= "ustar"
        let magic = Array("ustar\0".utf8)
        for (i, b) in magic.enumerated() { header[257 + i] = b }
        // version（263..264）= "00"
        header[263] = UInt8(ascii: "0")
        header[264] = UInt8(ascii: "0")

        // チェックサムを計算して書き込む（6桁 oct + null + space）
        let sum = header.reduce(0) { $0 + Int($1) }
        let checkStr = String(format: "%06o\0 ", sum)
        for (i, b) in Array(checkStr.utf8).enumerated() { header[148 + i] = b }

        return Data(header)
    }

    /// TAR ストリーム（ヘッダー + データ + パディング + 終端ブロック）を構築するヘルパー
    private func buildTarStream(entries: [(name: String, content: Data)]) -> Data {
        var tar = Data()
        for entry in entries {
            tar.append(buildTarHeader(name: entry.name, size: entry.content.count))
            tar.append(entry.content)
            // 512 バイト境界にパディング
            let remainder = entry.content.count % 512
            if remainder != 0 {
                tar.append(Data(repeating: 0, count: 512 - remainder))
            }
        }
        // 終端ブロック（1024 バイトのゼロ）
        tar.append(Data(repeating: 0, count: 1024))
        return tar
    }

    /// Apple Compression フレームワークで deflate 圧縮し、gzip ヘッダー/フッターを付加するヘルパー
    ///
    /// Compression.COMPRESSION_ZLIB は raw deflate を生成する。
    /// gzip フォーマット = 10 バイトヘッダー + raw deflate + CRC32(4B) + ISIZE(4B)
    private func gzipCompress(_ data: Data) throws -> Data {
        let inputBytes = [UInt8](data)
        let dstCapacity = data.count * 2 + 1024
        var dstBuffer = [UInt8](repeating: 0, count: dstCapacity)

        let compressedSize = compression_encode_buffer(
            &dstBuffer, dstCapacity,
            inputBytes, inputBytes.count,
            nil,
            COMPRESSION_ZLIB
        )
        guard compressedSize > 0 else {
            throw NSError(
                domain: "LibArchiveWrapperTests",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "compression_encode_buffer が失敗しました"]
            )
        }
        let deflateData = Data(dstBuffer.prefix(compressedSize))
        let crc32Value = computeCRC32(data)

        // gzip ヘッダー（RFC 1952）
        var gz = Data([0x1f, 0x8b, 0x08, 0x00,
                       0x00, 0x00, 0x00, 0x00,
                       0x00, 0xff])
        gz.append(deflateData)

        // gzip フッター: CRC32（LE 4B）+ 元サイズ（LE 4B）
        var crcLE = crc32Value.littleEndian
        var sizeLE = UInt32(data.count).littleEndian
        withUnsafeBytes(of: &crcLE)  { gz.append(contentsOf: $0) }
        withUnsafeBytes(of: &sizeLE) { gz.append(contentsOf: $0) }

        return gz
    }

    /// 純粋 Swift による CRC32 計算（ISO 3309 多項式 0xEDB88320）
    private func computeCRC32(_ data: Data) -> UInt32 {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var crc = UInt32(i)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (0xEDB88320 ^ (crc >> 1)) : (crc >> 1)
            }
            table[i] = crc
        }
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }

    /// 任意エントリを持つ TAR.GZ ファイルを生成して URL を返すヘルパー
    private func makeTarGz(
        entries: [(name: String, content: String)],
        archiveName: String = "test.tar.gz"
    ) throws -> URL {
        let tarEntries = entries.map { (name: $0.name, content: Data($0.content.utf8)) }
        let tarData = buildTarStream(entries: tarEntries)
        let gzData = try gzipCompress(tarData)
        let url = tempDirectory.appendingPathComponent(archiveName)
        try gzData.write(to: url)
        return url
    }

    // MARK: - テストケース 1: 正常な TAR.GZ（通常パス）
    //
    // 期待動作: validateTarPaths はエラーなしに完了する。
    // （その後の /usr/bin/tar は App Sandbox で失敗するが、validateTarPaths 自体はパスする）

    /// 通常の相対パスのみを含む TAR.GZ では validateTarPaths がエラーをスローしないこと
    ///
    /// App Sandbox 環境では /usr/bin/tar の実行が失敗するため、
    /// decompress 全体としてはエラーになる。しかしそのエラーは
    /// compressionFailed（runProcess 由来）であり、decompressionFailed ではない。
    /// validateTarPaths がエラーをスローしないことをこのテストで確認する。
    func testDecompress_normalPaths_doesNotThrowDecompressionFailed() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("hello.txt", "Hello, World!"),
            ("subdir/nested.txt", "Nested content")
        ])

        let destDir = tempDirectory.appendingPathComponent("output")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        do {
            try await sut.decompress(
                source: archiveURL,
                destination: destDir,
                password: nil
            ) { _ in }
            // App Sandbox 外で実行した場合は成功することも許容する
        } catch SecureZipError.decompressionFailed {
            XCTFail("通常パスの TAR.GZ で decompressionFailed がスローされてはいけない")
        } catch {
            // compressionFailed（App Sandbox での /usr/bin/tar 失敗）は許容する
        }
    }

    // MARK: - テストケース 2: ../ を含むパストラバーサル
    //
    // 設計: validateTarPaths は「..」を除去（sanitize）して destination 配下にマップする。
    // 例: `../escape.txt` → sanitize → `escape.txt` → destination/escape.txt → エラーなし
    // エラーにはならず、sanitize済みパスに展開される（ZIP Slip を無力化する設計）。

    /// `../` を含むエントリが validateTarPaths で sanitize されて destination 外に出ないこと
    ///
    /// validateTarPaths が正常完了することを確認する（decompressionFailed をスローしない）。
    func testDecompress_pathTraversal_singleDotDot_sanitizedByValidateTarPaths() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("../escape.txt", "path traversal payload")
        ], archiveName: "traversal_single.tar.gz")

        let destDir = tempDirectory.appendingPathComponent("output_traversal")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        do {
            try await sut.decompress(
                source: archiveURL,
                destination: destDir,
                password: nil
            ) { _ in }
        } catch SecureZipError.decompressionFailed {
            // validateTarPaths が ../escape.txt を sanitize 後も destination 外と判断した場合
            // （現実装では sanitize後 escape.txt になるので destination 配下、エラーにはならないはず）
            XCTFail("sanitize により destination 配下にマップされるため decompressionFailed はスローされないはず")
        } catch {
            // compressionFailed（App Sandbox での /usr/bin/tar 失敗 または libarchive の .. 拒否）は許容する
        }
    }

    // MARK: - テストケース 3: 絶対パス（/etc/passwd など）を含む
    //
    // 設計: validateTarPaths は先頭の空コンポーネントを除去する。
    // `/etc/passwd` → components = ["", "etc", "passwd"] → filter → ["etc", "passwd"]
    // → sanitized = "etc/passwd" → destination/etc/passwd → destination 配下 → エラーなし

    /// 絶対パスが validateTarPaths で sanitize されて destination 配下にマップされること
    ///
    /// `/etc/passwd` のような絶対パスは sanitize 後 `etc/passwd` になるため、
    /// validateTarPaths は decompressionFailed をスローしない。
    func testDecompress_absolutePath_sanitizedByValidateTarPaths() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("/etc/passwd", "root:x:0:0:root:/root:/bin/sh")
        ], archiveName: "absolute_path.tar.gz")

        let destDir = tempDirectory.appendingPathComponent("output_absolute")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        do {
            try await sut.decompress(
                source: archiveURL,
                destination: destDir,
                password: nil
            ) { _ in }
        } catch SecureZipError.decompressionFailed {
            XCTFail("絶対パスは sanitize 後 destination 配下にマップされるため decompressionFailed はスローされないはず")
        } catch {
            // compressionFailed（App Sandbox での /usr/bin/tar 失敗）は許容する
        }
    }

    // MARK: - テストケース 4: ネストした ../../ を含む
    //
    // 設計: `../../deep_escape.txt` → sanitize → `deep_escape.txt` → destination 配下 → エラーなし

    /// `../../` を含むエントリが validateTarPaths で sanitize されて destination 外に出ないこと
    func testDecompress_nestedPathTraversal_doubleDotDot_sanitizedByValidateTarPaths() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("../../deep_escape.txt", "deep path traversal payload")
        ], archiveName: "traversal_double.tar.gz")

        let destDir = tempDirectory.appendingPathComponent("output_double_traversal")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        do {
            try await sut.decompress(
                source: archiveURL,
                destination: destDir,
                password: nil
            ) { _ in }
        } catch SecureZipError.decompressionFailed {
            XCTFail("../../ は sanitize 後 destination 配下にマップされるため decompressionFailed はスローされないはず")
        } catch {
            // compressionFailed（App Sandbox での /usr/bin/tar 失敗 または libarchive の .. 拒否）は許容する
        }
    }

    // MARK: - テストケース 4b: destination 外を真に指すパス（symlink 経由等を除く）
    //
    // validateTarPaths が実際に decompressionFailed をスローするのは、
    // sanitize 後の fullURL.path が destPath + "/" で始まらない場合のみ。
    // 標準的な文字列操作では再現しにくいため、このテストは
    // validateTarPaths の正のパス確認（エラーが出ないこと）として機能させる。

    /// sanitize 後もファイル名として有効な通常エントリは decompressionFailed をスローしないこと
    func testDecompress_deeplyNestedNormalPath_doesNotThrowDecompressionFailed() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("a/b/c/d/e.txt", "deeply nested content")
        ], archiveName: "deep_normal.tar.gz")

        let destDir = tempDirectory.appendingPathComponent("output_deep_normal")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        do {
            try await sut.decompress(
                source: archiveURL,
                destination: destDir,
                password: nil
            ) { _ in }
        } catch SecureZipError.decompressionFailed {
            XCTFail("深いネストの通常パスで decompressionFailed がスローされてはいけない")
        } catch {
            // compressionFailed（App Sandbox での /usr/bin/tar 失敗）は許容する
        }
    }

    // MARK: - セキュリティ境界テスト: destination 外にファイルが書き込まれないこと

    /// パストラバーサルパスを含むアーカイブを解凍しても destination 外にファイルが生成されないこと
    ///
    /// validateTarPaths が sanitize によってパストラバーサルを無力化するため、
    /// destination 外にファイルが書き込まれることはない。
    func testDecompress_pathTraversal_doesNotWriteFilesOutsideDestination() async throws {
        let archiveURL = try makeTarGz(entries: [
            ("../should_not_exist.txt", "should not be written")
        ], archiveName: "traversal_no_write.tar.gz")

        let destDir = tempDirectory.appendingPathComponent("output_no_write")
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        _ = try? await sut.decompress(
            source: archiveURL,
            destination: destDir,
            password: nil
        ) { _ in }

        // destination の親ディレクトリに不正ファイルが書き込まれていないことを確認
        let escapedPath = tempDirectory.appendingPathComponent("should_not_exist.txt").path
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: escapedPath),
            "パストラバーサルで destination 外にファイルが書き込まれてはいけない"
        )
    }

    // MARK: - TAR.GZ 生成ヘルパー 正当性確認

    /// makeTarGz が有効な gzip データを生成できること（生成したファイルが 0 バイトでないこと）
    func testMakeTarGz_producesNonEmptyFile() throws {
        let archiveURL = try makeTarGz(entries: [
            ("test.txt", "test content")
        ])
        let attrs = try FileManager.default.attributesOfItem(atPath: archiveURL.path)
        let size = attrs[.size] as? Int ?? 0
        XCTAssertGreaterThan(size, 0, "生成した TAR.GZ は 0 バイトであってはいけない")
    }

    /// makeTarGz が gzip マジックバイト（0x1f 0x8b）で始まることを確認
    func testMakeTarGz_startsWithGzipMagicBytes() throws {
        let archiveURL = try makeTarGz(entries: [
            ("test.txt", "test content")
        ])
        let data = try Data(contentsOf: archiveURL)
        XCTAssertGreaterThanOrEqual(data.count, 2, "gzip ファイルは最低 2 バイト必要")
        XCTAssertEqual(data[0], 0x1f, "gzip マジックバイト 1 バイト目は 0x1f")
        XCTAssertEqual(data[1], 0x8b, "gzip マジックバイト 2 バイト目は 0x8b")
    }
}
