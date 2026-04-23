import SwiftUI
import SwiftData

@main
struct ClipGuardApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(environment)
                .modelContainer(environment.modelContainer)
        } label: {
            MenuBarIconView(state: environment.iconState)
        }
        .menuBarExtraStyle(.window)

        Window("History", id: WindowID.history) {
            HistoryView()
                .environment(environment)
                .modelContainer(environment.modelContainer)
                .frame(minWidth: 680, minHeight: 460)
        }

        Settings {
            SettingsView()
                .environment(environment)
                .frame(width: 580, height: 460)
        }
    }
}

enum WindowID {
    static let history = "clipguard.history"
}
