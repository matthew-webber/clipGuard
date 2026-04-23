import Foundation

@MainActor
final class URLTrackingParamTransform: Transform {
    let id = "url.tracking-params"
    let kind = "url.tracking-params"
    private let ruleProvider: RuleProvider
    private let isEnabledProvider: () -> Bool

    init(ruleProvider: RuleProvider, isEnabled: @escaping () -> Bool = { true }) {
        self.ruleProvider = ruleProvider
        self.isEnabledProvider = isEnabled
    }

    var isEnabled: Bool { isEnabledProvider() }

    func apply(_ input: String, context: TransformContext) -> TransformResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstLine = trimmed.split(whereSeparator: \.isNewline).first,
              trimmed == String(firstLine) else {
            return nil
        }

        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme, !scheme.isEmpty,
              let host = components.host, !host.isEmpty,
              let items = components.queryItems, !items.isEmpty
        else { return nil }

        var fired: [String] = []
        let kept = items.filter { item in
            if let rule = ruleProvider.firstMatch(paramName: item.name) {
                fired.append(rule.id)
                return false
            }
            return true
        }

        guard fired.count > 0 else { return nil }
        components.queryItems = kept.isEmpty ? nil : kept

        guard let newURL = components.url?.absoluteString, newURL != trimmed else { return nil }

        let summary: String
        if fired.count == 1 {
            summary = "Removed 1 tracking parameter"
        } else {
            summary = "Removed \(fired.count) tracking parameters"
        }

        return TransformResult(newText: newURL, firedRuleIDs: fired, summary: summary, kind: kind)
    }
}
