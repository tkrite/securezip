import SwiftUI

@main
struct SecureZipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showCoreDataFallbackAlert = false

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    showCoreDataFallbackAlert = CoreDataStack.shared.isUsingFallbackStore
                }
                .alert(
                    NSLocalizedString("coredata.fallback.title", comment: ""),
                    isPresented: $showCoreDataFallbackAlert
                ) {
                    Button(NSLocalizedString("coredata.fallback.ok", comment: ""), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("coredata.fallback.message", comment: ""))
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
