import SwiftUI

struct URLRulesSettingsTab: View {
    @Environment(AppEnvironment.self) private var env
    @State private var newParam: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            defaults
            Divider()
            userAdded
        }
        .padding(2)
    }

    private var defaults: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Built-in rules", systemImage: "shield.lefthalf.filled")
                .font(.callout.bold())
            Text("Toggle any default parameter. These ship with ClipGuard.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(env.ruleProvider.defaultRules) { rule in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { !env.ruleProvider.userRemovedRuleIDs.contains(rule.id) },
                                set: { env.toggleBuiltinRule(rule.id, enabled: $0) }
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: rule.isGlob ? "asterisk" : "tag")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(rule.pattern)
                                        .font(.system(.callout, design: .monospaced))
                                    if let note = rule.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        Divider().opacity(0.4)
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.35)))
        }
    }

    private var userAdded: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Your rules", systemImage: "person.crop.circle.badge.plus")
                .font(.callout.bold())
            Text("Add any extra query parameter names you want stripped. Supports * wildcards (e.g. spam_*).")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("e.g. spam_id", text: $newParam)
                    .textFieldStyle(.roundedBorder)
                Button {
                    env.addUserParam(newParam)
                    newParam = ""
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .disabled(newParam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if env.ruleProvider.userAddedParams.isEmpty {
                Text("No custom rules yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(Array(env.ruleProvider.userAddedParams).sorted(), id: \.self) { name in
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text(name)
                                .font(.system(size: 11, weight: .medium))
                            Button {
                                env.removeUserParam(name)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.14)))
                    }
                }
            }
        }
    }
}
