import XCTest
@testable import SecureZip

final class PasswordServiceTests: XCTestCase {

    private var sut: PasswordService!

    override func setUp() {
        sut = PasswordService()
    }

    // MARK: - 生成テスト

    func testGeneratePassword_hasCorrectLength() {
        let pw = sut.generatePassword(length: 16, includeUppercase: true,
                                      includeLowercase: true, includeNumbers: true, includeSymbols: true)
        XCTAssertEqual(pw.count, 16)
    }

    func testGeneratePassword_onlyUppercase_containsOnlyUppercase() {
        let pw = sut.generatePassword(length: 20, includeUppercase: true,
                                      includeLowercase: false, includeNumbers: false, includeSymbols: false)
        XCTAssertTrue(pw.allSatisfy { $0.isUppercase })
    }

    func testGeneratePassword_isDifferentEachTime() {
        let pw1 = sut.generatePassword(length: 16, includeUppercase: true,
                                       includeLowercase: true, includeNumbers: true, includeSymbols: true)
        let pw2 = sut.generatePassword(length: 16, includeUppercase: true,
                                       includeLowercase: true, includeNumbers: true, includeSymbols: true)
        // 確率的に同じになる可能性は極めて低い
        XCTAssertNotEqual(pw1, pw2)
    }

    // MARK: - 強度評価テスト

    func testEvaluateStrength_shortPassword_isWeak() {
        XCTAssertEqual(sut.evaluateStrength("abc"), .weak)
    }

    func testEvaluateStrength_longComplexPassword_isStrong() {
        XCTAssertEqual(sut.evaluateStrength("Abcd1234!@#$5678"), .strong)
    }

    func testEvaluateStrength_8charWithVariety_isGoodOrStrong() {
        let strength = sut.evaluateStrength("Ab1!Cd2@")
        XCTAssertGreaterThanOrEqual(strength, .good)
    }
}
