import AppKit

struct FrontmostApp: Equatable {
    let bundleID: String?
    let localizedName: String?
}

@MainActor
final class FrontmostAppResolver {
    func current() -> FrontmostApp {
        let app = NSWorkspace.shared.frontmostApplication
        return FrontmostApp(
            bundleID: app?.bundleIdentifier,
            localizedName: app?.localizedName
        )
    }

    func icon(for bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    func displayName(for bundleID: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        return (try? url.resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }

    func runningApps() -> [FrontmostApp] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let bid = app.bundleIdentifier else { return nil }
                return FrontmostApp(bundleID: bid, localizedName: app.localizedName)
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
