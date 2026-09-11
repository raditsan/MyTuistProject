import Foundation
import UserNotifications

/// Jenis suara yang diasosiasikan dengan notifikasi.
public enum NotificationSound: Equatable, Sendable {
    case defaultSound
    case none
    case named(String)

    public var unSound: UNNotificationSound? {
        switch self {
        case .defaultSound:
            return .default
        case .none:
            return nil
        case .named(let name):
            return UNNotificationSound(named: UNNotificationSoundName(name))
        }
    }
}

/// Model data strongly-typed yang merepresentasikan notifikasi (Push APNs maupun Local).
public struct NotificationPayload: Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let body: String
    public let badge: NSNumber?
    public let sound: NotificationSound
    public let deepLinkURL: URL?
    public let actionIdentifier: String?
    public let userInfo: [String: String]

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        body: String,
        badge: NSNumber? = nil,
        sound: NotificationSound = .defaultSound,
        deepLinkURL: URL? = nil,
        actionIdentifier: String? = nil,
        userInfo: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.badge = badge
        self.sound = sound
        self.deepLinkURL = deepLinkURL ?? Self.extractDeepLinkURL(from: userInfo)
        self.actionIdentifier = actionIdentifier
        self.userInfo = userInfo
    }

    /// Membuat payload dari UNNotificationContent dan identifier.
    public init(
        id: String,
        content: UNNotificationContent,
        actionIdentifier: String? = nil
    ) {
        var parsedUserInfo: [String: String] = [:]
        for (key, value) in content.userInfo {
            if let stringKey = key as? String {
                parsedUserInfo[stringKey] = "\(value)"
            }
        }

        self.init(
            id: id,
            title: content.title,
            subtitle: content.subtitle,
            body: content.body,
            badge: content.badge,
            sound: content.sound != nil ? .defaultSound : .none,
            deepLinkURL: Self.extractDeepLinkURL(from: parsedUserInfo),
            actionIdentifier: actionIdentifier,
            userInfo: parsedUserInfo
        )
    }

    /// Membuat payload dari UNNotificationResponse (saat user mengetuk notifikasi / action).
    public init(response: UNNotificationResponse) {
        self.init(
            id: response.notification.request.identifier,
            content: response.notification.request.content,
            actionIdentifier: response.actionIdentifier
        )
    }

    // MARK: - Helper URL Extraction
    /// Mengekstrak Deep Link URL dari berbagai kemungkinan key payload push notification (misal: "deeplink", "url", "link", "target_url").
    public static func extractDeepLinkURL(from dictionary: [String: String]) -> URL? {
        let candidateKeys = ["deeplink", "deep_link", "url", "link", "target_url", "targetUrl", "route"]
        for key in candidateKeys {
            if let value = dictionary[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return url
                }
            }
        }
        return nil
    }
}
