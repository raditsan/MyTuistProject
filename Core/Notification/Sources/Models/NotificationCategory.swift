import Foundation
import UserNotifications

/// Kategori notifikasi untuk mengelompokkan tombol aksi interaktif (Actionable Notification).
public struct NotificationCategory: Equatable, Sendable {
    public let identifier: String
    public let actions: [NotificationAction]
    public let intentIdentifiers: [String]
    public let hiddenPreviewsBodyPlaceholder: String?

    public init(
        identifier: String,
        actions: [NotificationAction] = [],
        intentIdentifiers: [String] = [],
        hiddenPreviewsBodyPlaceholder: String? = nil
    ) {
        self.identifier = identifier
        self.actions = actions
        self.intentIdentifiers = intentIdentifiers
        self.hiddenPreviewsBodyPlaceholder = hiddenPreviewsBodyPlaceholder
    }

    public func makeUNNotificationCategory() -> UNNotificationCategory {
        let unActions = actions.map { $0.makeUNNotificationAction() }
        if let placeholder = hiddenPreviewsBodyPlaceholder {
            return UNNotificationCategory(
                identifier: identifier,
                actions: unActions,
                intentIdentifiers: intentIdentifiers,
                hiddenPreviewsBodyPlaceholder: placeholder,
                options: []
            )
        } else {
            return UNNotificationCategory(
                identifier: identifier,
                actions: unActions,
                intentIdentifiers: intentIdentifiers,
                options: []
            )
        }
    }
}
