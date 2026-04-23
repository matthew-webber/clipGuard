import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private let defaults: UserDefaults
    private enum Key {
        static let enabled = "cg.enabled"
        static let urlCleanup = "cg.urlCleanupEnabled"
        static let notifications = "cg.showNotifications"
        static let blacklist = "cg.blacklistedBundleIDs"
        static let userAdded = "cg.userAddedParams"
        static let userRemoved = "cg.userRemovedRuleIDs"
    }

    var enabled: Bool {
        didSet { defaults.set(enabled, forKey: Key.enabled) }
    }
    var urlCleanupEnabled: Bool {
        didSet { defaults.set(urlCleanupEnabled, forKey: Key.urlCleanup) }
    }
    var showNotifications: Bool {
        didSet { defaults.set(showNotifications, forKey: Key.notifications) }
    }
    var blacklistedBundleIDs: Set<String> {
        didSet { persist(blacklistedBundleIDs, forKey: Key.blacklist) }
    }
    var userAddedParams: Set<String> {
        didSet { persist(userAddedParams, forKey: Key.userAdded) }
    }
    var userRemovedRuleIDs: Set<String> {
        didSet { persist(userRemovedRuleIDs, forKey: Key.userRemoved) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.enabled: true,
            Key.urlCleanup: true,
            Key.notifications: false
        ])
        self.enabled = defaults.bool(forKey: Key.enabled)
        self.urlCleanupEnabled = defaults.bool(forKey: Key.urlCleanup)
        self.showNotifications = defaults.bool(forKey: Key.notifications)
        self.blacklistedBundleIDs = Self.load(Key.blacklist, from: defaults)
        self.userAddedParams = Self.load(Key.userAdded, from: defaults)
        self.userRemovedRuleIDs = Self.load(Key.userRemoved, from: defaults)
    }

    private func persist(_ value: Set<String>, forKey key: String) {
        if let data = try? JSONEncoder().encode(Array(value)) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load(_ key: String, from defaults: UserDefaults) -> Set<String> {
        guard let data = defaults.data(forKey: key),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(arr)
    }
}
