import SwiftUI

struct HistoryRowView: View {
    @Environment(AppEnvironment.self) private var env
    let event: ClipEvent
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.undone ? "arrow.uturn.backward.circle" : "scissors.circle.fill")
                .font(.title3)
                .foregroundStyle(event.undone ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.transformedText)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 4) {
                    AppIconChip(
                        bundleID: event.sourceBundleID,
                        name: event.sourceAppName,
                        resolver: env.resolver
                    )
                    ChipView(
                        systemImage: "tag",
                        text: ruleSummary,
                        style: .accent,
                        help: event.firedRuleIDs.joined(separator: ", ")
                    )
                    if event.undone {
                        ChipView(systemImage: "arrow.uturn.backward", text: "Undone", style: .neutral)
                    }
                    Spacer()
                    CompactRelativeTimeText(date: event.timestamp)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
    }

    private var ruleSummary: String {
        let n = event.firedRuleIDs.count
        return n == 1 ? "1 rule" : "\(n) rules"
    }
}
