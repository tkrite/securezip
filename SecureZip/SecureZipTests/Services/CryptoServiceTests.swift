import XCTest
@testable import SecureZip

final class CryptoServiceTests: XCTestCase {

    private var sut: CryptoService!

    override func setUp() {
        sut = CryptoService()
    }

    func testGenerateDefaultPassword_hasDefaultLength() {
        let pw = sut.generateDefaultPassword()
        XCTAssertEqual(pw.count, PasswordService.defaultLength)
    }

    func testGenerateKeyPair_publicKeyMatchesPrivateKey() {
        let (privateKey, publicKey) = sut.generateKeyPair()
        // Curve25519 公開鍵は対応する秘密鍵から生成されていること
        XCTAssertEqual(privateKey.publicKey.rawRepresentation, publicKey.rawRepresentation)
    }
}
