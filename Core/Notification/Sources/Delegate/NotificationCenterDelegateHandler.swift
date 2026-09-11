import Foundation
import Combine
import UserNotifications

/// Handler yang mengimplementasikan UNUserNotificationCenterDelegate.
/// Memproses penerimaan notifikasi saat aplikasi aktif (foreground) dan interaksi ketukan user (open/tap/action),
/// serta menyediakannya dalam bentuk stream Combine Publisher dan closure callback.
public final class NotificationCenterDelegateHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationCenterDelegateHandler()

    // Opsi tampilan notifikasi saat aplikasi berada di foreground
    public var foregroundPresentationOptions: UNNotificationPresentationOptions = [.banner, .badge, .sound]

    // Callback closures opsional
    public var onNotificationReceived: ((NotificationPayload) -> Void)?
    public var onNotificationOpened: ((NotificationPayload) -> Void)?

    // Combine Subjects
    private let openedSubject = PassthroughSubject<NotificationPayload, Never>()
    private let receivedSubject = PassthroughSubject<NotificationPayload, Never>()

    public var openedPublisher: AnyPublisher<NotificationPayload, Never> {
        openedSubject.eraseToAnyPublisher()
    }

    public var receivedPublisher: AnyPublisher<NotificationPayload, Never> {
        receivedSubject.eraseToAnyPublisher()
    }

    public override init() {
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Dipanggil saat notifikasi tiba ketika aplikasi sedang aktif di FOREGROUND.
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let payload = NotificationPayload(
            id: notification.request.identifier,
            content: notification.request.content
        )
        handleWillPresent(payload: payload, completionHandler: completionHandler)
    }

    internal func handleWillPresent(
        payload: NotificationPayload,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        receivedSubject.send(payload)
        onNotificationReceived?(payload)
        completionHandler(foregroundPresentationOptions)
    }

    /// Dipanggil saat PENGGUNA MENGETUK notifikasi atau memilih tombol aksi (Actionable Notification).
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let payload = NotificationPayload(response: response)
        handleDidReceive(payload: payload, completionHandler: completionHandler)
    }

    internal func handleDidReceive(
        payload: NotificationPayload,
        completionHandler: @escaping () -> Void
    ) {
        openedSubject.send(payload)
        onNotificationOpened?(payload)
        completionHandler()
    }
}
