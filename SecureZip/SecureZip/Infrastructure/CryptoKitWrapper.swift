import Foundation
import CryptoKit

/// CryptoKit のラッパー
///
/// パスワード生成（SecRandomCopyBytes）や
/// 公開鍵暗号（Curve25519）のユーティリティを提供する。
final class CryptoKitWrapper {

    /// 指定バイト数の暗号学的乱数を生成する
    static func randomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        guard status == errSecSuccess else {
            throw SecureZipError.keychainError(status: status)
        }
        return Data(bytes)
    }

    /// Curve25519 鍵ペアを生成する（Phase 4）
    static func generateCurve25519KeyPair() -> (
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        publicKey: Curve25519.KeyAgreement.PublicKey
    ) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }
}
