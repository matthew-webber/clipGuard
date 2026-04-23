import Foundation

struct TrackingParamRule: Codable, Hashable, Identifiable {
    let id: String
    let pattern: String
    let note: String?

    var isGlob: Bool { pattern.contains("*") }

    func matches(_ name: String) -> Bool {
        guard isGlob else { return pattern == name }
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
        let full = "^" + escaped + "$"
        guard let regex = try? NSRegularExpression(pattern: full, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        return regex.firstMatch(in: name, options: [], range: range) != nil
    }
}

struct TrackingParamRuleSet: Codable {
    var rules: [TrackingParamRule]
}
