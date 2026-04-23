import Testing
import Foundation
@testable import clipGuard

@MainActor
struct URLTrackingParamTransformTests {
    private func makeTransform() -> URLTrackingParamTransform {
        let provider = RuleProvider(bundle: .main)
        // If bundled JSON isn't reachable in test target, seed a minimal rule set manually.
        if provider.defaultRules.isEmpty {
            provider.userAddedParams = [
                "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
                "gclid", "fbclid", "mc_cid", "mc_eid", "si", "ref", "source"
            ]
        }
        return URLTrackingParamTransform(ruleProvider: provider)
    }

    private func ctx() -> TransformContext {
        TransformContext(sourceBundleID: nil, sourceAppName: nil)
    }

    @Test func stripsCommonTrackingParams() {
        let t = makeTransform()
        let input = "https://example.com/path?utm_source=x&utm_medium=y&foo=bar"
        let result = t.apply(input, context: ctx())
        #expect(result?.newText == "https://example.com/path?foo=bar")
        #expect(result?.firedRuleIDs.count == 2)
    }

    @Test func preservesFragmentAndPath() {
        let t = makeTransform()
        let input = "https://example.com/a/b/c?gclid=abc&q=hello#section-2"
        let result = t.apply(input, context: ctx())
        #expect(result?.newText == "https://example.com/a/b/c?q=hello#section-2")
    }

    @Test func removesAllQueryWhenEveryParamMatches() {
        let t = makeTransform()
        let input = "https://example.com/x?utm_source=a&utm_medium=b"
        let result = t.apply(input, context: ctx())
        #expect(result?.newText == "https://example.com/x")
    }

    @Test func nonURLTextPassesThrough() {
        let t = makeTransform()
        #expect(t.apply("hello world", context: ctx()) == nil)
        #expect(t.apply("not a url at all ?utm_source=x", context: ctx()) == nil)
    }

    @Test func urlWithoutTrackingParamsIsUntouched() {
        let t = makeTransform()
        #expect(t.apply("https://example.com/?q=swift", context: ctx()) == nil)
        #expect(t.apply("https://example.com/", context: ctx()) == nil)
    }

    @Test func idempotentOnAlreadyCleanedURL() {
        let t = makeTransform()
        let cleaned = "https://example.com/?foo=bar"
        #expect(t.apply(cleaned, context: ctx()) == nil)
    }

    @Test func preservesPortAndUserInfo() {
        let t = makeTransform()
        let input = "https://user:pass@example.com:8443/path?utm_source=a&x=1"
        let result = t.apply(input, context: ctx())
        #expect(result?.newText.contains("user:pass@example.com:8443") == true)
        #expect(result?.newText.contains("x=1") == true)
        #expect(result?.newText.contains("utm_source") == false)
    }

    @Test func globPatternMatchesUTMFamily() {
        let provider = RuleProvider(bundle: Bundle(for: GlobMarker.self))
        provider.userRemovedRuleIDs = Set(provider.defaultRules.map(\.id))
        provider.userAddedParams = ["utm_*"]
        let t = URLTrackingParamTransform(ruleProvider: provider)
        let result = t.apply("https://example.com/?utm_custom_x=1&utm_campaign=c&keep=1", context: ctx())
        #expect(result?.newText == "https://example.com/?keep=1")
    }

    @Test func whitespaceTrimmedButMultilineRejected() {
        let t = makeTransform()
        #expect(t.apply("  https://example.com/?utm_source=x  ", context: ctx())?.newText == "https://example.com/")
        #expect(t.apply("https://a.com/?utm_source=x\nother line", context: ctx()) == nil)
    }
}

/// Marker class used only to obtain the test bundle.
private final class GlobMarker {}
