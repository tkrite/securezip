import Foundation

extension URL {
    /// ファイルサイズ（bytes）を返す。取得できない場合は nil
    var fileSize: Int64? {
        guard isFileURL else { return nil }
        return (try? resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) }
    }

    /// ファイルサイズの人間可読な文字列
    var fileSizeDescription: String {
        guard let size = fileSize else { return "不明" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
