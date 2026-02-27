import SwiftUI
import AppKit

/// パスワード生成シート
struct PasswordGeneratorSheet: View {

    @Binding var password: String
    @Environment(\.dismiss) private var dismiss

    @State private var length: Int = 16
    @State private var includeUppercase: Bool = true
    @State private var includeLowercase: Bool = true
    @State private var includeNumbers: Bool = true
    @State private var includeSymbols: Bool = true
    @State private var generatedPassword: String = ""

    private let service = PasswordService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("パスワード生成")
                .font(.title3.bold())

            GroupBox("生成設定") {
                VStack(alignment: .leading, spacing: 8) {
                    Stepper("文字数: \(length)", value: $length, in: 8...64)
                    Toggle("大文字 (A-Z)", isOn: $includeUppercase)
                    Toggle("小文字 (a-z)", isOn: $includeLowercase)
                    Toggle("数字 (0-9)",   isOn: $includeNumbers)
                    Toggle("記号 (!@#...)", isOn: $includeSymbols)
                }
                .padding(4)
            }

            // 生成結果
            GroupBox("生成されたパスワード") {
                HStack {
                    Text(generatedPassword.isEmpty ? "---" : generatedPassword)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Spacer()
                    Button("コピー") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generatedPassword, forType: .string)
                    }
                    .disabled(generatedPassword.isEmpty)
                }
                .padding(4)
            }

            let strength = service.evaluateStrength(generatedPassword)
            if !generatedPassword.isEmpty {
                Label("強度: \(strength.displayName)", systemImage: strength.symbolName)
                    .font(.caption)
            }

            HStack {
                Button("再生成") { generate() }
                Spacer()
                Button("キャンセル") { dismiss() }
                Button("適用") {
                    password = generatedPassword
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(generatedPassword.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
        .onAppear { generate() }
    }

    private func generate() {
        generatedPassword = service.generatePassword(
            length: length,
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSymbols: includeSymbols
        )
    }
}
