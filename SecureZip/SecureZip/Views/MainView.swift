import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case compress   = "compress"
    case decompress = "decompress"
    case send       = "send"
    case history    = "history"
    case settings   = "settings"

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .compress:   return "圧縮"
        case .decompress: return "解凍"
        case .send:       return "送信"
        case .history:    return "履歴"
        case .settings:   return "設定"
        }
    }

    var symbolName: String {
        switch self {
        case .compress:   return "archivebox"
        case .decompress: return "archivebox.fill"
        case .send:       return "paperplane"
        case .history:    return "clock"
        case .settings:   return "gear"
        }
    }
}

struct MainView: View {

    @State private var selection: SidebarItem? = .compress

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.label, systemImage: item.symbolName)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        } detail: {
            switch selection {
            case .compress:   CompressView()
            case .decompress: DecompressView()
            case .send:       SendView()
            case .history:    HistoryView()
            case .settings:   SettingsView()
            case nil:         Text("メニューから機能を選択してください")
            }
        }
        .frame(minWidth: 760, minHeight: 520)
    }
}

#Preview {
    MainView()
}
