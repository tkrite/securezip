import Foundation

/// Gmail REST API クライアント
///
/// MIME メッセージを Base64URL エンコードして Gmail API に送信する。
final class GmailAPIClient {

    private let session: URLSession
    static let sendEndpoint = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/send")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// メールを送信する
    func sendEmail(
        to recipient: String,
        subject: String,
        body: String,
        attachment: URL?
    ) async throws {
        // TODO: 以下の手順で実装
        // 1. MIME メッセージを構築（添付ファイルは Base64 エンコード）
        // 2. MIME 全体を Base64URL エンコード
        // 3. POST /gmail/v1/users/me/messages/send を呼び出す
        // 4. 401 → GTMAppAuth でトークンリフレッシュ後にリトライ
        // 5. 429 → リトライ（バックオフ）
        // 6. 5xx → ユーザーに通知
    }

    // MARK: - Private Helpers

    private func buildMIMEMessage(
        to: String,
        subject: String,
        body: String,
        attachment: URL?
    ) throws -> Data {
        // TODO: MIME メッセージ構築処理を実装
        return Data()
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
