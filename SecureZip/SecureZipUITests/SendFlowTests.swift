import XCTest

final class SendFlowTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    /// Gmail 未連携時に誘導メッセージが表示されることを確認する
    func testSendView_gmailNotConnected_showsPrompt() throws {
        app.outlines.buttons["送信"].click()
        XCTAssertTrue(app.staticTexts["Gmail 連携が必要です"].exists)
    }

    // TODO: Gmail 連携 → ファイル選択 → 送信 → キャンセル の E2E テストを実装
}
