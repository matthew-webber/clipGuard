import SwiftUI

struct CompactRelativeTimeText: View {
    let date: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(CompactRelativeTime.format(date: date, now: context.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .help(date.formatted(date: .abbreviated, time: .standard))
        }
    }
}

enum CompactRelativeTime {
    static func format(date: Date, now: Date = .now) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 { return "< 1m" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86_400 { return "\(seconds / 3600)h" }
        return "\(seconds / 86_400)d"
    }
}
