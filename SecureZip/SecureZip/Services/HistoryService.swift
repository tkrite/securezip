import Foundation
import CoreData

// MARK: - Protocol

protocol HistoryServiceProtocol {
    func fetchAll() async throws -> [HistoryItem]
    func save(_ item: HistoryItem) async throws
    func delete(id: UUID) async throws
    func deleteExpired() async throws
}

// MARK: - DTO

struct HistoryItem: Identifiable {
    let id: UUID
    let recipientEmail: String
    let fileName: String
    let originalFileNames: [String]
    let fileSize: Int64
    let format: CompressionFormat
    let isEncrypted: Bool
    var sentAt: Date?
    var expiresAt: Date?
    var status: SendStatus
    let createdAt: Date
}

// MARK: - Implementation

/// 送付履歴の CRUD を管理するサービス
final class HistoryService: HistoryServiceProtocol {

    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    func fetchAll() async throws -> [HistoryItem] {
        // TODO: Core Data fetch request を実装
        return []
    }

    func save(_ item: HistoryItem) async throws {
        // TODO: Core Data への保存処理を実装
    }

    func delete(id: UUID) async throws {
        // TODO: Core Data からの削除処理を実装
    }

    /// expiresAt を過ぎた履歴を一括削除する
    func deleteExpired() async throws {
        // TODO: expiresAt < Date() の履歴を削除し、
        //        対応する Keychain パスワードも削除する
    }
}
