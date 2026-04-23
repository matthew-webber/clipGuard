import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "scissors.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text("ClipGuard")
                .font(.title.bold())
            Text("A tiny menu bar utility that quietly removes tracking junk from URLs you copy.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 6) {
                row("link", "Strips tracking parameters from copied URLs")
                row("clock.arrow.circlepath", "Every change is reversible from history")
                row("nosign", "Blacklist apps to skip processing")
                row("lock.shield", "All data stays on your Mac")
            }
            .padding(.top, 6)
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(.tint)
            Text(text)
                .font(.callout)
            Spacer()
        }
    }
}
