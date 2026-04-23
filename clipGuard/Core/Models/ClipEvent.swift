import Foundation
import SwiftData

@Model
final class ClipEvent {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var originalText: String
    var transformedText: String
    var sourceBundleID: String?
    var sourceAppName: String?
    var firedRuleIDs: [String]
    var transformKind: String
    var undone: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        originalText: String,
        transformedText: String,
        sourceBundleID: String?,
        sourceAppName: String?,
        firedRuleIDs: [String],
        transformKind: String,
        undone: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.originalText = originalText
        self.transformedText = transformedText
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.firedRuleIDs = firedRuleIDs
        self.transformKind = transformKind
        self.undone = undone
    }
}
