import Foundation
import Combine
import UserNotifications

/// Protokol utama pengelola notifikasi sistem (Push Notification APNs & Local Notification).
public protocol NotificationServiceProtocol: Sendable {
    // MARK: - Authorization & APNs Token
    /// Meminta izin notifikasi dari pengguna (alert, badge, sound).
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    /// Memeriksa status izin notifikasi saat ini.
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    /// Mengonversi raw data token APNs menjadi format hexadecimal string 64-karakter standar.
    func formatDeviceToken(_ deviceToken: Data) -> String

    // MARK: - Local Notification Scheduling
    /// Menjadwalkan notifikasi lokal dengan pemicu kustom (TimeInterval atau Calendar).
    func schedule(payload: NotificationPayload, trigger: UNNotificationTrigger?) async throws

    /// Menjadwalkan notifikasi lokal berdasarkan jeda waktu (time interval) dalam detik.
    func scheduleTimeInterval(
        id: String,
        title: String,
        subtitle: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool,
        userInfo: [String: String],
        deepLinkURL: URL?,
        sound: NotificationSound,
        badge: NSNumber?
    ) async throws

    /// Menjadwalkan notifikasi lokal berdasarkan komponen kalender (tanggal, jam, menit).
    func scheduleCalendar(
        id: String,
        title: String,
        subtitle: String,
        body: String,
        dateComponents: DateComponents,
        repeats: Bool,
        userInfo: [String: String],
        deepLinkURL: URL?,
        sound: NotificationSound,
        badge: NSNumber?
    ) async throws

    // MARK: - Cancellation & Querying
    /// Menghapus notifikasi yang masih tertunda berdasarkan daftar ID.
    func removePending(ids: [String]) async
    /// Menghapus seluruh notifikasi lokal yang masih tertunda di antrean.
    func removeAllPending() async
    /// Menghapus notifikasi yang sudah tampil di Notification Center berdasarkan ID.
    func removeDelivered(ids: [String]) async
    /// Menghapus seluruh notifikasi yang sudah tampil di Notification Center.
    func removeAllDelivered() async
    /// Mengambil daftar ID notifikasi yang masih tertunda.
    func getPendingNotificationIDs() async -> [String]
    /// Mengambil daftar ID notifikasi yang sudah terkirim/tampil.
    func getDeliveredNotificationIDs() async -> [String]

    // MARK: - Badge Management
    /// Mengatur angka badge aplikasi pada ikon home screen.
    func setBadgeCount(_ count: Int) async throws
    /// Menghapus angka badge aplikasi (set to 0).
    func clearBadge() async throws

    // MARK: - Actionable Categories
    /// Mendaftarkan kategori tombol aksi interaktif untuk notifikasi.
    func registerCategories(_ categories: [NotificationCategory]) async

    // MARK: - Reactive Event Streaming
    /// Publisher yang memancarkan payload saat pengguna membuka atau mengetuk notifikasi.
    var openedNotificationPublisher: AnyPublisher<NotificationPayload, Never> { get }
    /// Publisher yang memancarkan payload saat notifikasi tiba ketika aplikasi sedang aktif di foreground.
    var receivedNotificationPublisher: AnyPublisher<NotificationPayload, Never> { get }
}

// MARK: - Default Implementations for Optional Parameters
extension NotificationServiceProtocol {
    public func requestAuthorization() async throws -> Bool {
        try await requestAuthorization(options: [.alert, .badge, .sound])
    }

    public func scheduleTimeInterval(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool = false,
        userInfo: [String: String] = [:],
        deepLinkURL: URL? = nil,
        sound: NotificationSound = .defaultSound,
        badge: NSNumber? = nil
    ) async throws {
        try await scheduleTimeInterval(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            timeInterval: timeInterval,
            repeats: repeats,
            userInfo: userInfo,
            deepLinkURL: deepLinkURL,
            sound: sound,
            badge: badge
        )
    }

    public func scheduleCalendar(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        body: String,
        dateComponents: DateComponents,
        repeats: Bool = false,
        userInfo: [String: String] = [:],
        deepLinkURL: URL? = nil,
        sound: NotificationSound = .defaultSound,
        badge: NSNumber? = nil
    ) async throws {
        try await scheduleCalendar(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            dateComponents: dateComponents,
            repeats: repeats,
            userInfo: userInfo,
            deepLinkURL: deepLinkURL,
            sound: sound,
            badge: badge
        )
    }
}
