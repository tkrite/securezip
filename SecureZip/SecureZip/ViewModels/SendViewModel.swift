import Foundation
import Combine

final class SendViewModel: ObservableObject {

    // MARK: - State

    @Published var recipientEmail: String = ""
    @Published var subject: String = ""
    @Published var body: String = ""
    @Published var selectedFile: URL?
    @Published var password: String = ""
    @Published var isSeparatePasswordEnabled: Bool = true
    @Published var cancelDelaySeconds: Int = 5
    @Published var countdown: Int = 0
    @Published var isSending: Bool = false
    @Published var isCountingDown: Bool = false
    @Published var errorMessage: String?
    @Published var isCompleted: Bool = false

    // MARK: - Dependencies

    private let gmailService: GmailServiceProtocol
    private let passwordService: PasswordServiceProtocol
    private let historyService: HistoryServiceProtocol
    private var sendTask: Task<Void, Error>?

    init(gmailService: GmailServiceProtocol = GmailService(),
         passwordService: PasswordServiceProtocol = PasswordService(),
         historyService: HistoryServiceProtocol = HistoryService()) {
        self.gmailService = gmailService
        self.passwordService = passwordService
        self.historyService = historyService
    }

    var isGmailAuthenticated: Bool { gmailService.isAuthenticated }

    // MARK: - Validation

    var canSend: Bool {
        recipientEmail.isValidEmail
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
            // カウントダウン（キャンセル・エラーは早期リターン）
            do {
                for remaining in stride(from: cancelDelaySeconds, through: 1, by: -1) {
                    try Task.checkCancellation()
                    await MainActor.run { countdown = remaining }
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                try Task.checkCancellation()
            } catch {
                await MainActor.run {
                    isCountingDown = false
                    countdown = 0
                }
                return
            }

            await MainActor.run {
                isCountingDown = false
                isSending = true
            }

            // 送信実行：エラー・キャンセルいずれの場合も isSending を false にリセットする
            do {
                try await gmailService.sendWithSeparatePassword(
                    file: file,
                    password: password,
                    recipient: recipientEmail,
                    subject: subject.isEmpty ? "ファイルを送付します" : subject,
                    body: body,
                    separatePassword: isSeparatePasswordEnabled
                )
                await MainActor.run {
                    isSending = false
                    isCompleted = true
                }
                // 送信成功後に履歴を保存（失敗しても送信完了扱いとする）
                let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0
                let historyItem = HistoryItem(
                    id: UUID(),
                    recipientEmail: recipientEmail,
                    fileName: file.lastPathComponent,
                    originalFileNames: [file.lastPathComponent],
                    fileSize: fileSize,
                    format: .zip,
                    isEncrypted: !password.isEmpty,
                    sentAt: Date(),
                    expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                    status: .sent,
                    createdAt: Date()
                )
                try? await historyService.save(historyItem)
            } catch is CancellationError {
                await MainActor.run { isSending = false }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// 送信をキャンセルする
    @MainActor
    func cancelSending() {
        sendTask?.cancel()
        sendTask = nil
        isCountingDown = false
        isSending = false
        countdown = 0
    }

    func generatePassword() {
        password = passwordService.generatePassword(
            length: PasswordService.defaultLength,
            includeUppercase: true,
            includeLowercase: true,
            includeNumbers: true,
            includeSymbols: true
        )
    }

}
