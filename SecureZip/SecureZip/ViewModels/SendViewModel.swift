import Foundation
import Observation

@Observable
final class SendViewModel {

    // MARK: - State

    var recipientEmail: String = ""
    var subject: String = ""
    var body: String = ""
    var selectedFile: URL?
    var password: String = ""
    var isSeparatePasswordEnabled: Bool = true
    var cancelDelaySeconds: Int = 5
    var countdown: Int = 0
    var isSending: Bool = false
    var isCountingDown: Bool = false
    var errorMessage: String?
    var isCompleted: Bool = false

    // MARK: - Dependencies

    private let gmailService: GmailServiceProtocol
    private var sendTask: Task<Void, Error>?

    init(gmailService: GmailServiceProtocol = GmailService()) {
        self.gmailService = gmailService
    }

    var isGmailAuthenticated: Bool { gmailService.isAuthenticated }

    // MARK: - Validation

    var canSend: Bool {
        isValidEmail(recipientEmail)
        && selectedFile != nil
        && !isSending
        && gmailService.isAuthenticated
    }

    // MARK: - Actions

    /// 送信ボタン押下 → カウントダウン開始
    func startSending() {
        guard canSend, let file = selectedFile else { return }
        isCountingDown = true
        countdown = cancelDelaySeconds

        sendTask = Task {
            // カウントダウン
            for remaining in stride(from: cancelDelaySeconds, through: 1, by: -1) {
                try Task.checkCancellation()
                await MainActor.run { countdown = remaining }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            try Task.checkCancellation()
            await MainActor.run {
                isCountingDown = false
                isSending = true
            }

            // 送信実行
            try await gmailService.sendWithSeparatePassword(
                file: file,
                password: password,
                recipient: recipientEmail,
                subject: subject.isEmpty ? "ファイルを送付します" : subject,
                body: body
            )

            await MainActor.run {
                isSending = false
                isCompleted = true
            }
        }
    }

    /// 送信をキャンセルする
    func cancelSending() {
        sendTask?.cancel()
        sendTask = nil
        isCountingDown = false
        isSending = false
        countdown = 0
    }

    func generatePassword() {
        password = PasswordService().generatePassword(
            length: PasswordService.defaultLength,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true
        )
    }

    // MARK: - Private

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
