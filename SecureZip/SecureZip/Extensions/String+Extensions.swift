import Foundation

extension String {
    /// RFC 5322 形式のメールアドレス検証
    ///
    /// - Note: ASCII ドメインのみ対応。国際化ドメイン名（IDN）は非対応。
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}
