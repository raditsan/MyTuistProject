import Foundation
import UserNotifications

/// Opsi tombol aksi notifikasi kustom.
public struct NotificationActionOptions: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let authenticationRequired = NotificationActionOptions(rawValue: 1 << 0)
    public static let destructive = NotificationActionOptions(rawValue: 1 << 1)
    public static let foreground = NotificationActionOptions(rawValue: 1 << 2)

    public var unOptions: UNNotificationActionOptions {
        var opts: UNNotificationActionOptions = []
        if contains(.authenticationRequired) { opts.insert(.authenticationRequired) }
        if contains(.destructive) { opts.insert(.destructive) }
        if contains(.foreground) { opts.insert(.foreground) }
        return opts
    }
}

/// Representasi tombol aksi interaktif pada notifikasi (misal: "Lihat Keranjang", "Hapus", "Buka").
public struct NotificationAction: Equatable, Sendable {
    public let identifier: String
    public let title: String
    public let options: NotificationActionOptions

    public init(
        identifier: String,
        title: String,
        options: NotificationActionOptions = []
    ) {
        self.identifier = identifier
        self.title = title
        self.options = options
    }

    public func makeUNNotificationAction() -> UNNotificationAction {
        UNNotificationAction(
            identifier: identifier,
            title: title,
            options: options.unOptions
        )
    }
}
