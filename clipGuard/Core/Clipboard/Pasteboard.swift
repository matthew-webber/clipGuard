import AppKit

protocol PasteboardAccessing: AnyObject {
    var changeCount: Int { get }
    func string() -> String?
    @discardableResult
    func setString(_ value: String) -> Int
}

final class NSPasteboardAdapter: PasteboardAccessing {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int { pasteboard.changeCount }

    func string() -> String? {
        pasteboard.string(forType: .string)
    }

    @discardableResult
    func setString(_ value: String) -> Int {
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        return pasteboard.changeCount
    }
}
