import Foundation
import Observation

@MainActor
@Observable
final class RuleProvider {
    private(set) var defaultRules: [TrackingParamRule] = []
    var userAddedParams: Set<String> = []
    var userRemovedRuleIDs: Set<String> = []

    init(bundle: Bundle = .main) {
        self.defaultRules = Self.loadDefaults(from: bundle)
    }

    var activeRules: [TrackingParamRule] {
        let builtin = defaultRules.filter { !userRemovedRuleIDs.contains($0.id) }
        let user = userAddedParams.map { name in
            TrackingParamRule(id: "user:\(name)", pattern: name, note: "User-added")
        }
        return builtin + user
    }

    func matches(paramName: String) -> [TrackingParamRule] {
        activeRules.filter { $0.matches(paramName) }
    }

    func firstMatch(paramName: String) -> TrackingParamRule? {
        activeRules.first { $0.matches(paramName) }
    }

    static func loadDefaults(from bundle: Bundle) -> [TrackingParamRule] {
        guard let url = bundle.url(forResource: "default-tracking-params", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let set = try? JSONDecoder().decode(TrackingParamRuleSet.self, from: data) else {
            return []
        }
        return set.rules
    }
}
