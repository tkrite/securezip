import Foundation
import CoreData

/// Core Data スタック管理
final class CoreDataStack {

    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SecureZip")
        container.loadPersistentStores { _, error in
            if let error {
                // TODO: 本番環境では適切なエラーハンドリングを実装
                fatalError("Core Data の読み込みに失敗しました: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// バックグラウンドコンテキストで処理を実行する
    func performBackground<T: Sendable>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw SecureZipError.coreDataError(underlying: error)
        }
    }
}
