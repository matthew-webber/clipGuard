import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppEnvironment.self) private var env
    @Query(sort: \ClipEvent.timestamp, order: .reverse) private var events: [ClipEvent]

    @State private var selection: ClipEvent.ID?
    @State private var searchText = ""
    @State private var confirmClear = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 320, ideal: 380)
        } detail: {
            detail
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search URLs or source app")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear history", systemImage: "trash")
                }
                .disabled(events.isEmpty)
            }
        }
        .confirmationDialog("Clear all history?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) {
                env.history.clearAll()
                selection = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every recorded clipboard event. This cannot be undone.")
        }
    }

    private var filtered: [ClipEvent] {
        guard !searchText.isEmpty else { return events }
        let needle = searchText.lowercased()
        return events.filter { e in
            e.originalText.lowercased().contains(needle) ||
            e.transformedText.lowercased().contains(needle) ||
            (e.sourceAppName ?? "").lowercased().contains(needle) ||
            (e.sourceBundleID ?? "").lowercased().contains(needle)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                events.isEmpty ? "No history yet" : "No matches",
                systemImage: events.isEmpty ? "tray" : "magnifyingglass",
                description: Text(events.isEmpty
                    ? "Copy a URL with tracking parameters to see events here."
                    : "Try a different search term.")
            )
        } else {
            List(selection: $selection) {
                ForEach(filtered) { event in
                    HistoryRowView(event: event, isSelected: selection == event.id)
                        .tag(event.id)
                        .listRowSeparator(.hidden)
                        .contextMenu {
                            Button("Copy original") { copy(event.originalText) }
                            Button("Copy cleaned") { copy(event.transformedText) }
                            if !event.undone {
                                Button("Undo") { env.undo(event) }
                            }
                            Divider()
                            Button("Delete", role: .destructive) { delete(event) }
                        }
                }
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selected = events.first(where: { $0.id == selection }) {
            detailView(for: selected)
        } else {
            ContentUnavailableView(
                "Select an event",
                systemImage: "hand.point.up.left",
                description: Text("Pick a clipboard event to see what changed.")
            )
        }
    }

    private func detailView(for event: ClipEvent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                AppIconChip(
                    bundleID: event.sourceBundleID,
                    name: event.sourceAppName,
                    resolver: env.resolver
                )
                ChipView(
                    systemImage: "clock",
                    text: event.timestamp.formatted(.relative(presentation: .named)),
                    style: .neutral
                )
                if event.undone {
                    ChipView(systemImage: "arrow.uturn.backward", text: "Undone", style: .neutral)
                }
                Spacer()
                if !event.undone {
                    Button {
                        env.undo(event)
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            URLDiffView(
                original: event.originalText,
                transformed: event.transformedText,
                firedRuleIDs: event.firedRuleIDs
            )

            rulesFired(event: event)

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func rulesFired(event: ClipEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Rules fired", systemImage: "checkmark.seal")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(event.firedRuleIDs, id: \.self) { id in
                    ChipView(systemImage: "tag", text: id, style: .accent)
                }
            }
        }
    }

    private func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func delete(_ event: ClipEvent) {
        if selection == event.id { selection = nil }
        env.history.delete(event)
    }
}

/// Lightweight wrapping layout for rule chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
