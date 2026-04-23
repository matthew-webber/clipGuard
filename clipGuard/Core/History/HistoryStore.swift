import Foundation
import SwiftData

@MainActor
final class HistoryStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func append(_ event: ClipEvent) {
        context.insert(event)
        try? context.save()
    }

    func recent(limit: Int = 200) -> [ClipEvent] {
        var descriptor = FetchDescriptor<ClipEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func all() -> [ClipEvent] {
        let descriptor = FetchDescriptor<ClipEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func markUndone(_ event: ClipEvent) {
        event.undone = true
        try? context.save()
    }

    func delete(_ event: ClipEvent) {
        context.delete(event)
        try? context.save()
    }

    func clearAll() {
        for event in all() {
            context.delete(event)
        }
        try? context.save()
    }
}
