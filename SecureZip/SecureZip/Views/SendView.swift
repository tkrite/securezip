import SwiftUI

struct SendView: View {

    @State private var vm = SendViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("送信")
                        .font(.title2.bold())
                    Spacer()
                }
                .padding()

                Divider()

                if !vm.isGmailAuthenticated {
                    // Gmail 未連携の誘導
                    ContentUnavailableView(
                        "Gmail 連携が必要です",
                        systemImage: "envelope.badge.shield.half.filled",
                        description: Text("設定画面から Gmail と連携してください。")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            GroupBox("送付先") {
                                TextField("メールアドレス", text: $vm.recipientEmail)
                                    .padding(4)
                            }

                            GroupBox("添付ファイル") {
                                HStack {
                                    Text(vm.selectedFile?.lastPathComponent ?? "ファイルが選択されていません")
                                        .foregroundStyle(vm.selectedFile == nil ? .secondary : .primary)
                                    Spacer()
                                    Button("選択...") {
                                        // TODO: NSOpenPanel でファイル選択
                                    }
                                }
                                .padding(4)
                            }

                            GroupBox("件名・本文") {
                                VStack {
                                    TextField("件名", text: $vm.subject)
                                    Divider()
                                    TextEditor(text: $vm.body)
                                        .frame(height: 80)
                                }
                                .padding(4)
                            }

                            GroupBox("オプション") {
                                Toggle("パスワードを別メールで送付する", isOn: $vm.isSeparatePasswordEnabled)
                                    .padding(4)
                            }

                            HStack {
                                Spacer()
                                Button("送信する") { vm.startSending() }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!vm.canSend)
                            }

                            if let msg = vm.errorMessage {
                                Text(msg).foregroundStyle(.red).font(.caption)
                            }
                        }
                        .padding()
                    }
                }
            }

            // 送信キャンセルオーバーレイ
            if vm.isCountingDown || vm.isSending {
                CancelOverlayView(
                    countdown: vm.countdown,
                    isSending: vm.isSending
                ) {
                    vm.cancelSending()
                }
            }
        }
    }
}
