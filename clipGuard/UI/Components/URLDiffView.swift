import SwiftUI

struct URLDiffView: View {
    let original: String
    let transformed: String
    let firedRuleIDs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            labeled("Original", systemImage: "doc.on.clipboard") {
                Text(annotatedOriginal)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
            }
            labeled("Cleaned", systemImage: "sparkles") {
                Text(transformed)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var annotatedOriginal: AttributedString {
        var out = AttributedString(original)
        guard let components = URLComponents(string: original),
              let items = components.queryItems else {
            return out
        }
        for item in items {
            let name = item.name
            let value = item.value ?? ""
            let fragment = value.isEmpty ? name : "\(name)=\(value)"
            if let range = out.range(of: fragment) {
                // Only strike if the parameter is one we removed (not present in transformed).
                if !transformed.contains(fragment) {
                    out[range].strikethroughStyle = .single
                    out[range].foregroundColor = .red
                }
            }
        }
        return out
    }

    @ViewBuilder
    private func labeled<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
        }
    }
}
