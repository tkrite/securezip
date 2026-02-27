import Foundation

/// 圧縮後の元ファイル処理方法
enum PostCompressionAction: String {
    case keep   = "keep"    // 保持
    case move   = "move"    // 移動（ゴミ箱）
    case delete = "delete"  // 完全削除
}

/// 元ファイルの扱いを制御するサービス（Phase 4 実装予定）
final class FileManagementService {

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// 圧縮完了後に元ファイルを指定アクションで処理する
    func handleOriginalFiles(_ urls: [URL], action: PostCompressionAction) throws {
        switch action {
        case .keep:
            break  // 何もしない
        case .move:
            for url in urls {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            }
        case .delete:
            for url in urls {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
