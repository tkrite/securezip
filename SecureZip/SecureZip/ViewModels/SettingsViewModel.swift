import Foundation
import Observation

@Observable
final class SettingsViewModel {

    // MARK: - Gmail

    var isGmailConnected: Bool = false
    var connectedEmail: String = ""

    // MARK: - Password

    var passwordLength: Int = 16
    var includeUppercase: Bool = true
    var includeLowercase: Bool = true
    var includeNumbers: Bool = true
    var includeSymbols: Bool = true

    // MARK: - AutoDelete

    var isAutoDeleteEnabled: Bool = true
    var autoDeleteDays: Int = 30

    // MARK: - Send

    var cancelDelaySeconds: Int = 5
    var separatePasswordByDefault: Bool = true

    // MARK: - PostCompression

    var postCompressionAction: PostCompressionAction = .keep

    // MARK: - Dependencies

    private let gmailService: GmailServiceProtocol

    init(gmailService: GmailServiceProtocol = GmailService()) {
        self.gmailService = gmailService
        self.isGmailConnected = gmailService.isAuthenticated
    }

    // MARK: - Actions

    func connectGmail() async {
        do {
            try await gmailService.authenticate()
            isGmailConnected = gmailService.isAuthenticated
        } catch {
            // TODO: エラー表示
        }
    }

    func disconnectGmail() async {
        do {
            try await gmailService.disconnect()
            isGmailConnected = false
            connectedEmail = ""
        } catch {
            // TODO: エラー表示
        }
    }
}
