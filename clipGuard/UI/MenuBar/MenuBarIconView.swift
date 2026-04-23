import SwiftUI

struct MenuBarIconView: View {
    let state: MenuBarIconState

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.hierarchical)
            .symbolEffect(.bounce, value: state == .flash)
    }

    private var symbol: String {
        switch state {
        case .idle: return "scissors.circle"
        case .disabled: return "pause.circle"
        case .flash: return "sparkles"
        }
    }
}
