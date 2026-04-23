import Foundation

@MainActor
final class TransformEngine {
    private(set) var transforms: [Transform]

    init(transforms: [Transform]) {
        self.transforms = transforms
    }

    func process(_ input: String, context: TransformContext) -> TransformResult? {
        var current = input
        var fired: [String] = []
        var kind = ""
        var summary = ""

        for transform in transforms where transform.isEnabled {
            guard let result = transform.apply(current, context: context) else { continue }
            guard result.newText != current else { continue }
            current = result.newText
            fired.append(contentsOf: result.firedRuleIDs)
            kind = result.kind
            summary = result.summary
        }

        guard current != input else { return nil }
        return TransformResult(newText: current, firedRuleIDs: fired, summary: summary, kind: kind)
    }
}
