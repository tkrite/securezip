import XCTest
@testable import SecureZip

// MARK: - Mock

private final class MockKeychainService: KeychainServiceProtocol {
    private var store: [String: Data] = [:]

    func save(_ data: Data, for key: String) throws { store[key] = data }
    func load(for key: String) throws -> Data {
        guard let data = store[key] else { throw NSError(domain: "MockKeychain", code: -1) }
        return data
    }
    func delete(for key: String) throws { store.removeValue(forKey: key) }
    func savePassword(_ password: String, historyID: UUID) throws {
        try save(Data(password.utf8), for: KeychainKey.passwordPrefix + historyID.uuidString)
    }
    func loadPassword(historyID: UUID) throws -> String {
        let data = try load(for: KeychainKey.passwordPrefix + historyID.uuidString)
        return String(decoding: data, as: UTF8.self)
    }
    func deletePassword(historyID: UUID) throws {
        try delete(for: KeychainKey.passwordPrefix + historyID.uuidString)
    }
}

// MARK: - Tests

final class HistoryServiceTests: XCTestCase {

    private var sut: HistoryService!

    override func setUp() {
        super.setUp()
        sut = HistoryService(
            coreDataStack: .inMemory(),
            keychainService: MockKeychainService()
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeItem(
        id: UUID = UUID(),
        recipientEmail: String = "test@example.com",
        expiresAt: Date? = Calendar.current.date(byAdding: .day, value: 30, to: Date())
    ) -> HistoryItem {
        HistoryItem(
            id: id,
            recipientEmail: recipientEmail,
            fileName: "archive.zip",
            originalFileNames: ["file.txt"],
            fileSize: 1024,
            format: .zip,
            isEncrypted: true,
            sentAt: Date(),
            expiresAt: expiresAt,
            status: .sent,
            createdAt: Date()
        )
    }

    // MARK: - fetchAll

    func testFetchAll_empty_returnsEmptyArray() async throws {
        let items = try await sut.fetchAll()
        XCTAssertTrue(items.isEmpty)
    }

    func testSave_andFetchAll_returnsItem() async throws {
        let item = makeItem()

        try await sut.save(item)
        let fetched = try await sut.fetchAll()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, item.id)
        XCTAssertEqual(fetched[0].recipientEmail, item.recipientEmail)
        XCTAssertEqual(fetched[0].fileName, item.fileName)
        XCTAssertEqual(fetched[0].fileSize, item.fileSize)
        XCTAssertEqual(fetched[0].isEncrypted, item.isEncrypted)
    }

    // MARK: - delete

    func testDelete_removesItem() async throws {
        let item = makeItem()
        try await sut.save(item)

        try await sut.delete(id: item.id)
        let fetched = try await sut.fetchAll()

        XCTAssertTrue(fetched.isEmpty)
    }

    func testDelete_nonExistentID_doesNotThrow() async throws {
        // 存在しない ID の削除はエラーにならないことを確認
        await XCTAssertNoThrowAsync(try await sut.delete(id: UUID()))
    }

    // MARK: - deleteExpired

    func testDeleteExpired_removesOnlyExpiredItems() async throws {
        let expiredItem = makeItem(
            id: UUID(),
            recipientEmail: "expired@example.com",
            expiresAt: Date(timeIntervalSinceNow: -1)  // 1秒前 = 期限切れ
        )
        let validItem = makeItem(
            id: UUID(),
            recipientEmail: "valid@example.com",
            expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        )

        try await sut.save(expiredItem)
        try await sut.save(validItem)

        try await sut.deleteExpired()
        let fetched = try await sut.fetchAll()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].recipientEmail, "valid@example.com")
    }

    func testDeleteExpired_noExpiresAt_isNotDeleted() async throws {
        let item = makeItem(expiresAt: nil)
        try await sut.save(item)

        try await sut.deleteExpired()
        let fetched = try await sut.fetchAll()

        XCTAssertEqual(fetched.count, 1)
    }
}

// MARK: - Async Test Helper

private func XCTAssertNoThrowAsync(
    _ expression: @autoclosure () async throws -> Void,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
    } catch {
        XCTFail(message.isEmpty ? "Unexpected error: \(error)" : message, file: file, line: line)
    }
}
