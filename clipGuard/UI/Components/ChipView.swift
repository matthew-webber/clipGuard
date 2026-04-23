import SwiftUI

struct ChipView: View {
    enum Style {
        case neutral
        case accent
        case destructive
        case success

        var fg: Color {
            switch self {
            case .neutral: return .secondary
            case .accent: return .accentColor
            case .destructive: return .red
            case .success: return .green
            }
        }

        var bg: Color {
            switch self {
            case .neutral: return .secondary.opacity(0.12)
            case .accent: return .accentColor.opacity(0.14)
            case .destructive: return .red.opacity(0.12)
            case .success: return .green.opacity(0.14)
            }
        }
    }

    let systemImage: String?
    let text: String
    var style: Style = .neutral
    var help: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(style.fg)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous).fill(style.bg)
        )
        .help(help ?? text)
    }
}

struct AppIconChip: View {
    let bundleID: String?
    let name: String?
    let resolver: FrontmostAppResolver

    var body: some View {
        HStack(spacing: 4) {
            if let bundleID, let icon = resolver.icon(for: bundleID) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 12, height: 12)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule(style: .continuous).fill(.secondary.opacity(0.12)))
        .help(bundleID ?? displayName)
    }

    private var displayName: String {
        name ?? bundleID ?? "Unknown"
    }
}
