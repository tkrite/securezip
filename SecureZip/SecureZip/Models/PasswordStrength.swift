import Foundation

/// パスワード強度の分類
enum PasswordStrength: Int, Comparable {
    case weak     = 0
    case fair     = 1
    case good     = 2
    case strong   = 3

    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// ユーザーに表示するラベル
    var displayName: String {
        switch self {
        case .weak:   return "弱い"
        case .fair:   return "普通"
        case .good:   return "良い"
        case .strong: return "強い"
        }
    }

    /// アイコン名（SF Symbols）
    var symbolName: String {
        switch self {
        case .weak:   return "exclamationmark.shield"
        case .fair:   return "shield"
        case .good:   return "checkmark.shield"
        case .strong: return "lock.shield.fill"
        }
    }
}
