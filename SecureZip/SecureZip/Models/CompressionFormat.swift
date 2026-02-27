import Foundation

/// 対応する圧縮形式
enum CompressionFormat: String, CaseIterable, Identifiable {
    case zip    = "zip"
    case tarGz  = "tar.gz"
    case tarBz2 = "tar.bz2"
    case tarZst = "tar.zst"

    var id: String { rawValue }

    /// ユーザーに表示するラベル
    var displayName: String {
        switch self {
        case .zip:    return "ZIP"
        case .tarGz:  return "TAR.GZ"
        case .tarBz2: return "TAR.BZ2"
        case .tarZst: return "TAR.ZST"
        }
    }

    /// ファイル拡張子
    var fileExtension: String { rawValue }

    /// AES-256暗号化に対応しているか
    /// - Note: libarchive の仕様上、暗号化は ZIP 形式のみ対応
    var supportsEncryption: Bool {
        self == .zip
    }
}
