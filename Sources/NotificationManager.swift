import Foundation
import UserNotifications

enum NotificationManager {

    /// Request notification permission. Safe to call multiple times.
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    /// Post a local notification about a validator state change.
    static func sendStateChangeNotification(
        validatorIndex: Int,
        isHealthy: Bool,
        statusLabel: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = isHealthy
            ? "Validator \(validatorIndex) Active"
            : "Validator \(validatorIndex) Inactive"
        content.body = isHealthy
            ? "Back online and attesting. Status: \(statusLabel)"
            : "Appears offline or inactive. Status: \(statusLabel)"
        content.sound = .default
        content.categoryIdentifier = "VALIDATOR_STATE_CHANGE"

        let request = UNNotificationRequest(
            identifier: "validator-\(validatorIndex)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
