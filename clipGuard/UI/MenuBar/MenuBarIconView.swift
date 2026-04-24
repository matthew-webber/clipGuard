import SwiftUI

struct MenuBarIconView: View {
    let state: MenuBarIconState

    var body: some View {
        Group {
            switch state {
            case .idle:
                Image(nsImage: Self.idleIconImage)
                    .resizable()
                    .frame(width: 22, height: 22)
            case .disabled:
                Image(systemName: "pause.circle")
                    .font(.system(size: 18))
            case .flash:
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
            }
        }
        .symbolRenderingMode(state == .idle ? .monochrome : .hierarchical)
        .symbolEffect(.bounce, value: state == .flash)
    }

    private static let idleIconImage: NSImage = {
        let imageSize = NSSize(width: 24, height: 24)
        let image = NSImage(size: imageSize)

        image.lockFocus()
        defer { image.unlockFocus() }

        if let shield = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 22, weight: .semibold)) {
            shield.draw(
                in: NSRect(x: 1, y: 1, width: 22, height: 22),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        if let scissors = NSImage(systemSymbolName: "scissors", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 10, weight: .bold)) {
            scissors.draw(
                in: NSRect(x: 7, y: 7, width: 10, height: 10),
                from: .zero,
                operation: .destinationOut,
                fraction: 1
            )
        }

        image.isTemplate = true
        return image
    }()
}
