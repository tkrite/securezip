import XCTest

final class CompressionFlowTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    /// 圧縮画面が表示され、基本 UI 要素が存在することを確認する
    func testCompressViewIsVisible() throws {
        // サイドバーの「圧縮」を選択
        app.outlines.buttons["圧縮"].click()

        // 圧縮ボタンが表示されること
        XCTAssertTrue(app.buttons["圧縮する"].exists)
    }

    // TODO: ファイルのドラッグ&ドロップ → 圧縮 → 完了 の E2E テストを実装
}
