import Foundation
import Security

// MARK: - Protocol

protocol PasswordServiceProtocol {
    func generatePassword(
        length: Int,
        includeUppercase: Bool,
        includeLowercase: Bool,
        includeNumbers: Bool,
        includeSymbols: Bool
    ) -> String

    func evaluateStrength(_ password: String) -> PasswordStrength
}

// MARK: - Implementation

/// パスワード生成・強度評価サービス
///
/// SecRandomCopyBytes を使用した暗号学的に安全なパスワードを生成する。
final class PasswordService: PasswordServiceProtocol {

    static let defaultLength = 16

    /// 暗号学的に安全なランダムパスワードを生成する
    func generatePassword(
        length: Int = defaultLength,
        includeUppercase: Bool = true,
        includeLowercase: Bool = true,
        includeNumbers: Bool = true,
        includeSymbols: Bool = true
    ) -> String {
        var charset = ""
        if includeUppercase { charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeLowercase { charset += "abcdefghijklmnopqrstuvwxyz" }
        if includeNumbers   { charset += "0123456789" }
        if includeSymbols   { charset += "!@#$%^&*()-_=+[]{}|;:,.<>?" }

        guard !charset.isEmpty else { return "" }

        let charsetArray = Array(charset)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        guard status == errSecSuccess else {
            // フォールバック（通常は発生しない）
            return String((0..<length).map { _ in charsetArray.randomElement()! })
        }
        return String(bytes.map { charsetArray[Int($0) % charsetArray.count] })
    }

    /// パスワード強度を評価する
    func evaluateStrength(_ password: String) -> PasswordStrength {
        let length = password.count
        let hasUpper  = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower  = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSymbol = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

        let varietyCount = [hasUpper, hasLower, hasNumber, hasSymbol].filter { $0 }.count

        switch (length, varietyCount) {
        case (..<8, _):              return .weak
        case (8..<12, ..<3):        return .fair
        case (8..<12, 3...):        return .good
        case (12..., ..<3):         return .good
        case (12..., 3...):         return .strong
        default:                    return .fair
        }
    }
}
