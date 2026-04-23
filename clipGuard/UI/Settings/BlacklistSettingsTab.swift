import SwiftUI
import AppKit

struct BlacklistSettingsTab: View {
    @Environment(AppEnvironment.self) private var env
    @State private var pickerApp: FrontmostApp?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Blacklisted source apps", systemImage: "nosign")
                .font(.callout.bold())
            Text("Clipboard copies originating from these apps pass through ClipGuard untouched and are not recorded in history.")
                .font(.caption)
                .foregroundStyle(.secondary)

            list

            Divider()

            addRow
        }
        .padding(2)
    }

    private var list: some View {
        let items = Array(env.settings.blacklistedBundleIDs).sorted()
        return Group {
            if items.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(.green)
                    Text("No apps blacklisted. Every source app is processed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.35)))
            } else {
                VStack(spacing: 0) {
                    ForEach(items, id: \.self) { bid in
                        HStack(spacing: 8) {
                            if let icon = env.resolver.icon(for: bid) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: "app.dashed")
                                    .foregroundStyle(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(env.resolver.displayName(for: bid) ?? bid)
                                    .font(.callout)
                                Text(bid)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                env.removeBlacklisted(bid)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        Divider().opacity(0.4)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.35)))
            }
        }
    }

    private var addRow: some View {
        HStack {
            Menu {
                ForEach(env.resolver.runningApps(), id: \.bundleID) { app in
                    if let bid = app.bundleID {
                        Button {
                            env.addBlacklisted(bid)
                        } label: {
                            Label(app.localizedName ?? bid, systemImage: "app")
                        }
                    }
                }
            } label: {
                Label("Add from running apps", systemImage: "plus.circle")
            }
            Spacer()
        }
    }
}
