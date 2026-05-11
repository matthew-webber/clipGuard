import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var settings = env.settings
        let loginItems = env.loginItems
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { settings.enabled },
                    set: { env.setEnabled($0) }
                )) {
                    Label("Watch clipboard", systemImage: "scissors.circle")
                }
                Toggle(isOn: $settings.urlCleanupEnabled) {
                    Label("Strip URL tracking parameters", systemImage: "link")
                }
                .disabled(!settings.enabled)
                Toggle(isOn: $settings.showNotifications) {
                    Label("Show notification on each transform", systemImage: "bell.badge")
                }
                .disabled(!settings.enabled)
            } header: {
                Text("Behavior")
            } footer: {
                Text("ClipGuard reads text from the clipboard, removes configured tracking parameters from URLs, and writes the cleaned URL back. Non-URL text is never modified.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { loginItems.setEnabled($0) }
                )) {
                    Label("Launch at login", systemImage: "power")
                }

                if let statusMessage = loginItems.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = loginItems.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Startup")
            } footer: {
                Text("Start ClipGuard automatically when you sign in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Status") {
                HStack {
                    Image(systemName: settings.enabled ? "circle.fill" : "pause.circle.fill")
                        .foregroundStyle(settings.enabled ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    Text(settings.enabled ? "Monitoring clipboard" : "Paused")
                        .font(.callout)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loginItems.refresh()
        }
    }
}
