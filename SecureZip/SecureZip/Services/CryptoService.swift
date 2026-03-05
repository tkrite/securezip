import Foundation
import CryptoKit

/// 公開鍵暗号処理を担当するサービス
///
/// Curve25519 公開鍵暗号は Phase 4 で実装予定。
/// パスワード生成が必要な場合は PasswordService を直接使用すること。
final class CryptoService {

    // MARK: - Phase 4: Curve25519 公開鍵暗号（将来実装）

    /// Curve25519 鍵ペアを生成する（Phase 4）
    func generateKeyPair() -> (privateKey: Curve25519.KeyAgreement.PrivateKey, publicKey: Curve25519.KeyAgreement.PublicKey) {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        return (privateKey, privateKey.publicKey)
    }
}
