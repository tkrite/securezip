import SwiftUI

struct DecompressView: View {

    @State private var vm = DecompressViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("解凍")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 20) {

                // ファイル選択
                GroupBox("解凍するファイルを選択") {
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

                // パスワード
                GroupBox("パスワード（暗号化ファイルの場合）") {
                    SecureField("パスワード（任意）", text: $vm.password)
                        .padding(4)
                }

                // 実行ボタン
                HStack {
                    Spacer()
                    Button("解凍する") {
                        // TODO: 解凍先フォルダ選択 → vm.decompress(destination:)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.canDecompress || vm.isDecompressing)
                }

                if vm.isDecompressing {
                    ProgressView(value: vm.progress)
                }

                if vm.isCompleted {
                    Label("解凍が完了しました", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                if let msg = vm.errorMessage {
                    Text(msg).foregroundStyle(.red).font(.caption)
                }
            }
            .padding()

            Spacer()
        }
    }
}
