import Foundation
import Combine
import GoogleSignIn

final class SettingsViewModel: ObservableObject {

    // MARK: - Gmail

    @Published var isGmailConnected: Bool = false
    @Published var connectedEmail: String = ""

    // MARK: - Password

    @Published var passwordLength: Int = 16
    @Published var includeUppercase: Bool = true
    @Published var includeLowercase: Bool = true
    @Published var includeNumbers: Bool = true
    @Published var includeSymbols: Bool = true

    // MARK: - AutoDelete

    @Published var isAutoDeleteEnabled: Bool = true
    @Published var autoDeleteDays: Int = 30

    // MARK: - Send

    @Published var cancelDelaySeconds: Int = 5
    @Published var separatePasswordByDefault: Bool = true

    // MARK: - PostCompression

    @Published var postCompressionAction: PostCompressionAction = .keep

    // MARK: - Error

    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let gmailService: GmailServiceProtocol

    init(gmailService: GmailServiceProtocol = GmailService()) {
        self.gmailService = gmailService
        self.isGmailConnected = gmailService.isAuthenticated
        self.connectedEmail = GIDSignIn.sharedInstance.currentUser?.profile?.email ?? ""
    }

    // MARK: - Actions

    func connectGmail() async {
        errorMessage = nil
        do {
            try await gmailService.authenticate()
            isGmailConnected = gmailService.isAuthenticated
            connectedEmail = GIDSignIn.sharedInstance.currentUser?.profile?.email ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnectGmail() async {
        errorMessage = nil
        do {
            try await gmailService.disconnect()
            isGmailConnected = false
            connectedEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
