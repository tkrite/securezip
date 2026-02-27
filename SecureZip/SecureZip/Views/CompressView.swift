import SwiftUI

struct CompressView: View {

    @State private var vm = CompressViewModel()
    @State private var showPasswordGenerator = false
    @State private var showSavePanel = false

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("圧縮")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ドロップゾーン
                    DropZoneView(files: $vm.selectedFiles)
                        .frame(height: 140)

                    // 圧縮形式
                    GroupBox("圧縮形式") {
                        Picker("", selection: $vm.format) {
                            ForEach(CompressionFormat.allCases) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // 暗号化
                    GroupBox("AES-256 暗号化") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("暗号化を有効にする", isOn: $vm.isEncryptionEnabled)
                                .disabled(!vm.format.supportsEncryption)

                            if !vm.format.supportsEncryption {
                                Text("暗号化は ZIP 形式のみ対応しています")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if vm.isEncryptionEnabled {
                                HStack {
                                    SecureField("パスワード", text: $vm.password)
                                        .onChange(of: vm.password) { _, _ in
                                            vm.updatePasswordStrength()
                                        }
                                    Button("自動生成") { vm.generatePassword() }
                                }
                                // 強度インジケーター
                                HStack {
                                    Image(systemName: vm.passwordStrength.symbolName)
                                    Text(vm.passwordStrength.displayName)
                                        .font(.caption)
                                }
                                .foregroundStyle(vm.password.isEmpty ? .secondary : .primary)
                            }
                        }
                        .padding(4)
                    }

                    // 実行ボタン
                    HStack {
                        Spacer()
                        Button("圧縮する") {
                            showSavePanel = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!vm.canCompress || vm.isCompressing)
                    }

                    // 進捗
                    if vm.isCompressing {
                        ProgressView(value: vm.progress)
                    }

                    // エラー
                    if let msg = vm.errorMessage {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
        .fileExporter(
            isPresented: $showSavePanel,
            document: nil as URL?,
            contentType: .zip,
            defaultFilename: "archive"
        ) { result in
            if case .success(let url) = result {
                Task { await vm.compress(destination: url) }
            }
        }
    }
}

#Preview {
    CompressView()
        .frame(width: 560, height: 520)
}
