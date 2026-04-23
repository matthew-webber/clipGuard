import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private var authRequested = false
    private var lastPostedAt: Date = .distantPast
    private let throttle: TimeInterval = 1.5

    func requestAuthorizationIfNeeded() {
        guard !authRequested else { return }
        authRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func postTransformed(summary: String, detail: String) {
        let now = Date()
        guard now.timeIntervalSince(lastPostedAt) >= throttle else { return }
        lastPostedAt = now

        let content = UNMutableNotificationContent()
        content.title = "ClipGuard"
        content.subtitle = summary
        content.body = detail
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
