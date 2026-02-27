import Foundation
import Security

/// Keychain Services の低レベルラッパー
///
/// KeychainService が利用する基底実装。
/// テスト時はモックで差し替える。
final class KeychainWrapper {

    static func set(_ data: Data, forKey key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String:               kSecClassGenericPassword,
            kSecAttrAccount as String:         key,
            kSecValueData as String:           data,
            kSecAttrAccessible as String:      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String:  false
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil)
    }

    static func get(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key,
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(forKey key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key
        ]
        return SecItemDelete(query as CFDictionary)
    }
}
