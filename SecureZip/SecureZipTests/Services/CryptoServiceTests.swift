import XCTest
@testable import SecureZip

final class CryptoServiceTests: XCTestCase {

    private var sut: CryptoService!

    override func setUp() {
        sut = CryptoService()
    }

    func testGenerateKeyPair_publicKeyMatchesPrivateKey() {
        let (privateKey, publicKey) = sut.generateKeyPair()
        // Curve25519 公開鍵は対応する秘密鍵から生成されていること
        XCTAssertEqual(privateKey.publicKey.rawRepresentation, publicKey.rawRepresentation)
    }

    func testGenerateKeyPair_eachCallProducesDifferentKeys() {
        let (_, publicKey1) = sut.generateKeyPair()
        let (_, publicKey2) = sut.generateKeyPair()
        // 毎回異なる鍵ペアが生成されること
        XCTAssertNotEqual(publicKey1.rawRepresentation, publicKey2.rawRepresentation)
    }
}
