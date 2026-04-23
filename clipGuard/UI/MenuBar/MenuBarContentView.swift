import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    @Query(sort: \ClipEvent.timestamp, order: .reverse) private var events: [ClipEvent]

    var body: some View {
        @Bindable var settings = env.settings

        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            recentSection
            Divider()
            footer
        }
        .frame(width: 340)
        .padding(.vertical, 8)
    }

    private var header: some View {
        @Bindable var settings = env.settings
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scissors.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ClipGuard")
                        .font(.system(.headline))
                    Text(env.settings.enabled ? "Watching clipboard" : "Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { env.settings.enabled },
                    set: { env.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .help(env.settings.enabled ? "Pause ClipGuard" : "Resume ClipGuard")
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var recentSection: some View {
        let recent = Array(events.prefix(5))
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Recent", systemImage: "clock")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if !events.isEmpty {
                    Text("\(events.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)

            if recent.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.secondary)
                    Text("No clipboard events yet. Copy a URL to see it here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            } else {
                VStack(spacing: 2) {
                    ForEach(recent) { event in
                        MenuRecentRow(event: event)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var footer: some View {
        VStack(spacing: 2) {
            menuButton("Open History", systemImage: "clock.arrow.circlepath") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: WindowID.history)
            }
            menuButton("Settings…", systemImage: "gearshape") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            menuButton("Quit ClipGuard", systemImage: "power") {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    private func menuButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverHighlightButtonStyle())
    }
}

private struct MenuRecentRow: View {
    @Environment(AppEnvironment.self) private var env
    let event: ClipEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: event.undone ? "arrow.uturn.backward.circle" : "scissors.circle.fill")
                .foregroundStyle(event.undone ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.transformedText)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 4) {
                    AppIconChip(
                        bundleID: event.sourceBundleID,
                        name: event.sourceAppName,
                        resolver: env.resolver
                    )
                    ChipView(
                        systemImage: "checkmark.seal",
                        text: "\(event.firedRuleIDs.count) rule\(event.firedRuleIDs.count == 1 ? "" : "s")",
                        style: .accent
                    )
                    Spacer()
                    Text(event.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(.clear))
        .contextMenu {
            Button("Copy original") { copy(event.originalText) }
            Button("Copy cleaned") { copy(event.transformedText) }
            if !event.undone {
                Button("Undo") { env.undo(event) }
            }
        }
    }

    private func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}

private struct HoverHighlightButtonStyle: ButtonStyle {
    @State private var hover = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hover ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .onHover { hover = $0 }
    }
}
