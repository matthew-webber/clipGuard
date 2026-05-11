import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class LoginItemController {
    private let service: SMAppService

    private(set) var isEnabled = false
    private(set) var statusMessage: String?
    private(set) var errorMessage: String?

    init(service: SMAppService = .mainApp) {
        self.service = service
        refresh()
    }

    func refresh() {
        switch service.status {
        case .enabled:
            isEnabled = true
            statusMessage = nil
        case .requiresApproval:
            isEnabled = false
            statusMessage = "Allow ClipGuard in System Settings to finish enabling launch at login."
        case .notFound:
            isEnabled = false
            statusMessage = "Launch at login is unavailable for this build."
        case .notRegistered:
            isEnabled = false
            statusMessage = nil
        @unknown default:
            isEnabled = false
            statusMessage = "Launch at login is unavailable right now."
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }
}
