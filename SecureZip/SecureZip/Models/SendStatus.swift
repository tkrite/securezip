import Foundation

/// 送付履歴の送信ステータス
enum SendStatus: String, CaseIterable {
    case created    = "created"
    case sending    = "sending"
    case sent       = "sent"
    case cancelled  = "cancelled"
    case failed     = "failed"

    /// ユーザーに表示するラベル
    var displayName: String {
        switch self {
        case .created:   return "作成済み"
        case .sending:   return "送信中"
        case .sent:      return "送信済み"
        case .cancelled: return "キャンセル"
        case .failed:    return "失敗"
        }
    }

    /// アイコン名（SF Symbols）
    var symbolName: String {
        switch self {
        case .created:   return "doc"
        case .sending:   return "arrow.up.circle"
        case .sent:      return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .failed:    return "exclamationmark.circle"
        }
    }
}
