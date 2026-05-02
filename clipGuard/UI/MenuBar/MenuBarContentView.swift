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
        return HStack(spacing: 8) {
            Text("ClipGuard")
                .font(.system(.headline))
            Spacer()
            Text(env.settings.enabled ? "Enabled" : "Disabled")
                .font(.caption)
                .foregroundStyle(env.settings.enabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            Toggle("", isOn: Binding(
                get: { env.settings.enabled },
                set: { env.setEnabled($0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help(env.settings.enabled ? "Pause ClipGuard" : "Resume ClipGuard")
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var recentSection: some View {
        let recent = Array(events.prefix(5))
        return VStack(alignment: .leading, spacing: 6) {
            ZStack {
                HStack(spacing: 4) {
                    Spacer()
                    Text("Recent")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    if !events.isEmpty {
                        Text("(\(events.count))")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if !events.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            env.history.clearAll()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Clear all history")
                    }
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
                    AppliedRulesChip(
                        ruleIDs: event.firedRuleIDs,
                        provider: env.ruleProvider
                    )
                    Spacer()
                    CompactRelativeTimeText(date: event.timestamp)
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

private struct AppliedRulesChip: View {
    let ruleIDs: [String]
    let provider: RuleProvider

    @State private var showRules = false
    @State private var hover = false

    var body: some View {
        Button {
            showRules.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 10, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.7)
                    .rotationEffect(.degrees(showRules ? 90 : 0))
            }
            .foregroundStyle(.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(hover || showRules ? 0.22 : 0.14))
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help(ruleIDs.count == 1 ? "Show applied rule" : "Show applied rules")
        .popover(isPresented: $showRules, arrowEdge: .trailing) {
            AppliedRulesPopover(ruleIDs: ruleIDs, provider: provider)
        }
    }

    private var label: String {
        ruleIDs.count == 1 ? "1 rule" : "\(ruleIDs.count) rules"
    }
}

private struct AppliedRulesPopover: View {
    let ruleIDs: [String]
    let provider: RuleProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.tint)
                    .font(.system(size: 12, weight: .semibold))
                Text(headerText)
                    .font(.system(.subheadline, weight: .semibold))
                Spacer(minLength: 8)
            }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(resolvedRules.enumerated()), id: \.offset) { _, rule in
                        AppliedRuleRow(rule: rule)
                    }
                }
                .padding(.trailing, 2)
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
    }

    private var headerText: String {
        ruleIDs.count == 1 ? "1 rule applied" : "\(ruleIDs.count) rules applied"
    }

    private var resolvedRules: [ResolvedAppliedRule] {
        ruleIDs.map { id in
            if let rule = provider.defaultRules.first(where: { $0.id == id }) {
                return ResolvedAppliedRule(
                    id: id,
                    pattern: rule.pattern,
                    note: rule.note,
                    source: .builtin
                )
            }
            if id.hasPrefix("user:") {
                return ResolvedAppliedRule(
                    id: id,
                    pattern: String(id.dropFirst("user:".count)),
                    note: nil,
                    source: .user
                )
            }
            return ResolvedAppliedRule(id: id, pattern: id, note: nil, source: .unknown)
        }
    }
}

private struct ResolvedAppliedRule {
    enum Source { case builtin, user, unknown }
    let id: String
    let pattern: String
    let note: String?
    let source: Source
}

private struct AppliedRuleRow: View {
    let rule: ResolvedAppliedRule

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(rule.pattern)
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.secondary.opacity(0.15))
                )
            VStack(alignment: .leading, spacing: 2) {
                if let note = rule.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if rule.source == .user {
                    Text("User-added")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }
            Spacer(minLength: 0)
        }
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
