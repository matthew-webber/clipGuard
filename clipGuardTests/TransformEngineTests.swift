import Testing
import Foundation
@testable import clipGuard

@MainActor
struct TransformEngineTests {
    final class MockTransform: Transform {
        let id: String
        let kind: String
        var isEnabled: Bool
        var handler: (String) -> TransformResult?
        init(id: String, kind: String = "mock", isEnabled: Bool = true, handler: @escaping (String) -> TransformResult?) {
            self.id = id
            self.kind = kind
            self.isEnabled = isEnabled
            self.handler = handler
        }
        func apply(_ input: String, context: TransformContext) -> TransformResult? { handler(input) }
    }

    private func ctx() -> TransformContext {
        TransformContext(sourceBundleID: nil, sourceAppName: nil)
    }

    @Test func returnsNilWhenNoTransformMatches() {
        let engine = TransformEngine(transforms: [
            MockTransform(id: "a") { _ in nil }
        ])
        #expect(engine.process("hello", context: ctx()) == nil)
    }

    @Test func appliesTransformsInOrder() {
        let t1 = MockTransform(id: "upper") { s in
            let out = s.uppercased()
            return out == s ? nil : TransformResult(newText: out, firedRuleIDs: ["upper"], summary: "u", kind: "upper")
        }
        let t2 = MockTransform(id: "suffix") { s in
            TransformResult(newText: s + "!", firedRuleIDs: ["suffix"], summary: "s", kind: "suffix")
        }
        let engine = TransformEngine(transforms: [t1, t2])
        let result = engine.process("hello", context: ctx())
        #expect(result?.newText == "HELLO!")
        #expect(result?.firedRuleIDs == ["upper", "suffix"])
    }

    @Test func skipsDisabledTransforms() {
        let t1 = MockTransform(id: "upper", isEnabled: false) { s in
            TransformResult(newText: s.uppercased(), firedRuleIDs: ["upper"], summary: "u", kind: "upper")
        }
        let t2 = MockTransform(id: "suffix") { s in
            TransformResult(newText: s + "!", firedRuleIDs: ["suffix"], summary: "s", kind: "suffix")
        }
        let engine = TransformEngine(transforms: [t1, t2])
        #expect(engine.process("hi", context: ctx())?.newText == "hi!")
    }

    @Test func noChangeMeansNoResult() {
        let t = MockTransform(id: "noop") { s in
            TransformResult(newText: s, firedRuleIDs: ["noop"], summary: "x", kind: "noop")
        }
        let engine = TransformEngine(transforms: [t])
        #expect(engine.process("hello", context: ctx()) == nil)
    }
}
