import XCTest
@testable import SecureZip

final class HistoryServiceTests: XCTestCase {

    private var sut: HistoryService!

    override func setUp() {
        // TODO: インメモリ Core Data スタックを使用したテスト環境を構築
        sut = HistoryService()
    }

    func testFetchAll_empty_returnsEmptyArray() async throws {
        let items = try await sut.fetchAll()
        XCTAssertTrue(items.isEmpty)
    }

    func testSave_andFetchAll_returnsItem() async throws {
        // TODO: HistoryItem を保存し、fetchAll で取得できることを検証
    }

    func testDelete_removesItem() async throws {
        // TODO: 保存した HistoryItem を削除し、fetchAll に現れないことを検証
    }

    func testDeleteExpired_removesOnlyExpiredItems() async throws {
        // TODO: expiresAt が過去の履歴のみ削除されることを検証
    }
}
