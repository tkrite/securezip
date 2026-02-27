import Foundation
import CryptoKit

/// パスワード・公開鍵暗号処理を担当するサービス
///
/// パスワード生成は PasswordService に委譲。
/// Curve25519 公開鍵暗号は Phase 4 で実装予定。
final class CryptoService {

    private let passwordService: PasswordServiceProtocol

    init(passwordService: PasswordServiceProtocol = PasswordService()) {
        self.passwordService = passwordService
    }

    /// デフォルト設定で安全なパスワードを生成する
    func generateDefaultPassword() -> String {
        passwordService.generatePassword(
            length: PasswordService.defaultLength,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true
        )
    }

    // MARK: - Phase 4: Curve25519 公開鍵暗号（将来実装）

    /// Curve25519 鍵ペアを生成する（Phase 4）
    func generateKeyPair() -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Curve25519.KeyAgreement.PublicKey) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }
}
