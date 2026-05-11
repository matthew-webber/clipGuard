import Foundation
import SwiftData
import AppKit
import Observation

enum MenuBarIconState: Equatable {
    case idle
    case disabled
    case flash
}

@MainActor
@Observable
final class AppEnvironment {
    let settings: AppSettings
    let ruleProvider: RuleProvider
    let pasteboard: PasteboardAccessing
    let resolver: FrontmostAppResolver
    let monitor: ClipboardMonitor
    let engine: TransformEngine
    let history: HistoryStore
    let notifications: NotificationService
    let loginItems: LoginItemController
    let modelContainer: ModelContainer

    private(set) var iconState: MenuBarIconState = .idle
    private var flashTask: Task<Void, Never>?

    init() {
        let settings = AppSettings()
        let ruleProvider = RuleProvider()
        let pasteboard = NSPasteboardAdapter()
        let resolver = FrontmostAppResolver()
        let notifications = NotificationService()
        let loginItems = LoginItemController()

        self.settings = settings
        self.ruleProvider = ruleProvider
        self.pasteboard = pasteboard
        self.resolver = resolver
        self.notifications = notifications
        self.loginItems = loginItems

        let monitor = ClipboardMonitor(pasteboard: pasteboard, resolver: resolver)
        self.monitor = monitor

        let urlTransform = URLTrackingParamTransform(
            ruleProvider: ruleProvider,
            isEnabled: { [settings] in settings.urlCleanupEnabled }
        )
        self.engine = TransformEngine(transforms: [urlTransform])

        let container: ModelContainer
        do {
            container = try ModelContainer(for: ClipEvent.self)
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: ClipEvent.self, configurations: config)
        }
        self.modelContainer = container
        self.history = HistoryStore(context: container.mainContext)

        // Hydrate user rule overrides from settings.
        ruleProvider.userAddedParams = settings.userAddedParams
        ruleProvider.userRemovedRuleIDs = settings.userRemovedRuleIDs

        monitor.onChange = { [weak self] change in
            self?.handle(change)
        }

        refreshIconState()
        if settings.enabled { monitor.start() }
    }

    // MARK: - Public controls

    func setEnabled(_ enabled: Bool) {
        settings.enabled = enabled
        if enabled {
            monitor.start()
        } else {
            monitor.stop()
        }
        refreshIconState()
    }

    func syncRuleOverrides() {
        settings.userAddedParams = ruleProvider.userAddedParams
        settings.userRemovedRuleIDs = ruleProvider.userRemovedRuleIDs
    }

    func addUserParam(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ruleProvider.userAddedParams.insert(trimmed)
        syncRuleOverrides()
    }

    func removeUserParam(_ name: String) {
        ruleProvider.userAddedParams.remove(name)
        syncRuleOverrides()
    }

    func toggleBuiltinRule(_ id: String, enabled: Bool) {
        if enabled {
            ruleProvider.userRemovedRuleIDs.remove(id)
        } else {
            ruleProvider.userRemovedRuleIDs.insert(id)
        }
        syncRuleOverrides()
    }

    func addBlacklisted(_ bundleID: String) {
        settings.blacklistedBundleIDs.insert(bundleID)
    }

    func removeBlacklisted(_ bundleID: String) {
        settings.blacklistedBundleIDs.remove(bundleID)
    }

    func undo(_ event: ClipEvent) {
        let post = pasteboard.setString(event.originalText)
        monitor.suppressNext(changeCount: post)
        history.markUndone(event)
    }

    // MARK: - Pipeline

    private func handle(_ change: ClipboardChange) {
        guard settings.enabled else { return }
        if let bid = change.source.bundleID, settings.blacklistedBundleIDs.contains(bid) {
            return
        }
        let context = TransformContext(
            sourceBundleID: change.source.bundleID,
            sourceAppName: change.source.localizedName
        )
        guard let result = engine.process(change.text, context: context) else { return }

        let post = pasteboard.setString(result.newText)
        monitor.suppressNext(changeCount: post)

        let event = ClipEvent(
            originalText: change.text,
            transformedText: result.newText,
            sourceBundleID: change.source.bundleID,
            sourceAppName: change.source.localizedName,
            firedRuleIDs: result.firedRuleIDs,
            transformKind: result.kind
        )
        history.append(event)

        if settings.showNotifications {
            notifications.requestAuthorizationIfNeeded()
            notifications.postTransformed(summary: result.summary, detail: result.newText)
        }

        flashIcon()
    }

    private func refreshIconState() {
        iconState = settings.enabled ? .idle : .disabled
    }

    private func flashIcon() {
        flashTask?.cancel()
        let previous: MenuBarIconState = settings.enabled ? .idle : .disabled
        iconState = .flash
        flashTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled, let self else { return }
            self.iconState = previous
        }
    }
}
