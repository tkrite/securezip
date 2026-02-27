import XCTest
@testable import SecureZip

@MainActor
final class SendViewModelTests: XCTestCase {

    private var sut: SendViewModel!

    override func setUp() {
        sut = SendViewModel()
    }

    func testCanSend_noEmail_isFalse() {
        XCTAssertFalse(sut.canSend)
    }

    func testCanSend_invalidEmail_isFalse() {
        sut.recipientEmail = "invalid-email"
        sut.selectedFile = URL(fileURLWithPath: "/tmp/test.zip")
        XCTAssertFalse(sut.canSend)
    }

    func testCancelSending_stopsCountdown() {
        sut.startSending()
        sut.cancelSending()
        XCTAssertFalse(sut.isCountingDown)
        XCTAssertFalse(sut.isSending)
    }
}
