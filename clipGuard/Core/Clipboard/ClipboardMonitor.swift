import Foundation
import AppKit
import Observation

struct ClipboardChange: Equatable {
    let text: String
    let source: FrontmostApp
}

@MainActor
@Observable
final class ClipboardMonitor {
    private let pasteboard: PasteboardAccessing
    private let resolver: FrontmostAppResolver
    private var timer: Timer?
    private var lastChangeCount: Int
    private var suppressedChangeCount: Int?

    var isRunning: Bool = false
    var onChange: ((ClipboardChange) -> Void)?

    init(pasteboard: PasteboardAccessing, resolver: FrontmostAppResolver) {
        self.pasteboard = pasteboard
        self.resolver = resolver
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = pasteboard.changeCount
        isRunning = true
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// After a self-initiated write, call this with the post-write changeCount so we don't re-process our own paste.
    func suppressNext(changeCount: Int) {
        suppressedChangeCount = changeCount
        lastChangeCount = changeCount
    }

    private func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        if let suppressed = suppressedChangeCount, suppressed == current {
            suppressedChangeCount = nil
            return
        }

        let source = resolver.current()
        guard let text = pasteboard.string(), !text.isEmpty else { return }
        onChange?(ClipboardChange(text: text, source: source))
    }
}
