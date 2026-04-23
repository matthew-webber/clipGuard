import Foundation

struct TransformResult: Equatable, Sendable {
    let newText: String
    let firedRuleIDs: [String]
    let summary: String
    let kind: String
}

struct TransformContext: Sendable {
    let sourceBundleID: String?
    let sourceAppName: String?
}
