import XCTest
@testable import SecureZip

@MainActor
final class CompressViewModelTests: XCTestCase {

    private var sut: CompressViewModel!

    override func setUp() {
        sut = CompressViewModel()
    }

    func testCanCompress_noFiles_isFalse() {
        XCTAssertFalse(sut.canCompress)
    }

    func testCanCompress_withFiles_isTrue() {
        sut.selectedFiles = [URL(fileURLWithPath: "/tmp/test.txt")]
        XCTAssertTrue(sut.canCompress)
    }

    func testCanCompress_encryptionEnabled_noPassword_isFalse() {
        sut.selectedFiles = [URL(fileURLWithPath: "/tmp/test.txt")]
        sut.isEncryptionEnabled = true
        sut.password = ""
        XCTAssertFalse(sut.canCompress)
    }

    func testGeneratePassword_setsNonEmptyPassword() {
        sut.generatePassword()
        XCTAssertFalse(sut.password.isEmpty)
    }

    func testUpdatePasswordStrength_updatesStrength() {
        sut.password = "weakpw"
        sut.updatePasswordStrength()
        XCTAssertEqual(sut.passwordStrength, .weak)

        sut.password = "StrongP@ss1234!"
        sut.updatePasswordStrength()
        XCTAssertGreaterThanOrEqual(sut.passwordStrength, .good)
    }

    func testEncryption_onlyAvailableForZip() {
        sut.format = .tarGz
        XCTAssertFalse(sut.format.supportsEncryption)
        sut.format = .zip
        XCTAssertTrue(sut.format.supportsEncryption)
    }
}
