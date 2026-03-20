import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let thresholds: [(minutes: Int, message: String)] = [
        (30, "AWS session expires in 30 minutes"),
        (15, "AWS session expires in 15 minutes"),
        (5, "AWS session expires in 5 minutes!"),
        (1, "AWS session expires in 1 minute!"),
        (0, "AWS session has expired"),
    ]

    override init() {
        super.init()
        center.delegate = self
        requestPermission()
    }

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleNotifications(for credentials: SAMLCredentials) {
        cancelAllNotifications()

        let expiresAt = credentials.expiresAt

        for threshold in thresholds {
            let fireDate = expiresAt.addingTimeInterval(-Double(threshold.minutes * 60))
            guard fireDate.timeIntervalSinceNow > 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "SAML2AWS"
            content.body = threshold.message
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: fireDate.timeIntervalSinceNow,
                repeats: false
            )

            let id = "saml2aws-\(threshold.minutes)min"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
