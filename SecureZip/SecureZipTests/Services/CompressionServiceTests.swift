import XCTest
@testable import SecureZip

final class CompressionServiceTests: XCTestCase {

    private var sut: CompressionService!
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        sut = CompressionService()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        sut = nil
    }

    // MARK: - 正常系

    func testCompress_zip_withoutPassword_succeeds() async throws {
        // TODO: テスト用ファイルを作成して ZIP 圧縮が成功することを検証
    }

    func testCompress_zip_withPassword_succeeds() async throws {
        // TODO: AES-256 暗号化 ZIP 圧縮が成功することを検証
    }

    func testCompress_tarGz_succeeds() async throws {
        // TODO: TAR.GZ 圧縮が成功することを検証
    }

    func testDecompress_zip_withoutPassword_succeeds() async throws {
        // TODO: ZIP 解凍が成功し元のファイルが復元されることを検証
    }

    func testDecompress_zip_withCorrectPassword_succeeds() async throws {
        // TODO: 正しいパスワードで暗号化 ZIP の解凍が成功することを検証
    }

    // MARK: - 異常系

    func testCompress_withEncryption_onTarGz_throwsError() async throws {
        let source = tempDirectory.appendingPathComponent("test.txt")
        FileManager.default.createFile(atPath: source.path, contents: Data("test".utf8))
        let dest = tempDirectory.appendingPathComponent("out.tar.gz")

        do {
            try await sut.compress(
                sources: [source],
                destination: dest,
                format: .tarGz,
                password: "password"
            ) { _ in }
            XCTFail("エラーがスローされるべき")
        } catch SecureZipError.encryptionNotSupported {
            // 期待通り
        }
    }

    func testDecompress_withWrongPassword_throwsError() async throws {
        // TODO: 誤ったパスワードで解凍すると適切なエラーがスローされることを検証
    }
}
