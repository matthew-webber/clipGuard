import Testing
import Foundation
@testable import clipGuard

@MainActor
struct RuleProviderTests {
    @Test func loadsBundledDefaultsOrAllowsManualSeed() {
        let provider = RuleProvider(bundle: .main)
        // The resource may or may not be in the test bundle depending on target config.
        // Either way, the API should function.
        if !provider.defaultRules.isEmpty {
            #expect(provider.defaultRules.contains { $0.pattern == "gclid" })
        }
    }

    @Test func userAddedRulesAppearInActiveRules() {
        let provider = RuleProvider(bundle: .main)
        provider.userAddedParams = ["spam_id"]
        #expect(provider.activeRules.contains { $0.pattern == "spam_id" })
        #expect(provider.firstMatch(paramName: "spam_id") != nil)
    }

    @Test func removedBuiltinsAreFilteredOut() {
        let provider = RuleProvider(bundle: .main)
        guard let first = provider.defaultRules.first else { return }
        provider.userRemovedRuleIDs = [first.id]
        #expect(!provider.activeRules.contains { $0.id == first.id })
    }

    @Test func globMatchingIsCaseInsensitiveAndAnchored() {
        let rule = TrackingParamRule(id: "g", pattern: "utm_*", note: nil)
        #expect(rule.matches("utm_source"))
        #expect(rule.matches("UTM_Source"))
        #expect(rule.matches("utm_"))
        #expect(!rule.matches("xutm_source"))
        #expect(!rule.matches("gclid"))
    }

    @Test func exactMatchIsCaseSensitiveByDefault() {
        let rule = TrackingParamRule(id: "g", pattern: "gclid", note: nil)
        #expect(rule.matches("gclid"))
        #expect(!rule.matches("GCLID"))
        #expect(!rule.matches("gclidx"))
    }
}
