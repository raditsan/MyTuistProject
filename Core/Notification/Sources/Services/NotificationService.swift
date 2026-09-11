import Foundation
import Combine
import UIKit
import UserNotifications

/// Internal executor wrapper untuk interaksi dengan UNUserNotificationCenter agar 100% testable dalam unit test.
internal struct NotificationCenterExecutor: @unchecked Sendable {
    private static var isUnhostedTest: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    var requestAuthorization: @Sendable (_ options: UNAuthorizationOptions) async throws -> Bool = { options in
        guard !Self.isUnhostedTest else { return true }
        return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }

    var getNotificationSettings: @Sendable () async -> UNNotificationSettings = {
        guard !Self.isUnhostedTest else {
            // UNNotificationSettings has no public init, return standard when testing
            fatalError("getNotificationSettings should be mocked in tests")
        }
        return await UNUserNotificationCenter.current().notificationSettings()
    }

    var add: @Sendable (_ request: UNNotificationRequest) async throws -> Void = { request in
        guard !Self.isUnhostedTest else { return }
        try await UNUserNotificationCenter.current().add(request)
    }

    var getPendingNotificationRequests: @Sendable () async -> [UNNotificationRequest] = {
        guard !Self.isUnhostedTest else { return [] }
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    var removePendingNotificationRequests: @Sendable (_ identifiers: [String]) -> Void = { ids in
        guard !Self.isUnhostedTest else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    var removeAllPendingNotificationRequests: @Sendable () -> Void = {
        guard !Self.isUnhostedTest else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    var getDeliveredNotifications: @Sendable () async -> [UNNotification] = {
        guard !Self.isUnhostedTest else { return [] }
        return await UNUserNotificationCenter.current().deliveredNotifications()
    }

    var removeDeliveredNotifications: @Sendable (_ identifiers: [String]) -> Void = { ids in
        guard !Self.isUnhostedTest else { return }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    var removeAllDeliveredNotifications: @Sendable () -> Void = {
        guard !Self.isUnhostedTest else { return }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    var setNotificationCategories: @Sendable (_ categories: Set<UNNotificationCategory>) -> Void = { categories in
        guard !Self.isUnhostedTest else { return }
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    var setBadgeCount: @Sendable (_ count: Int) async throws -> Void = { count in
        guard !Self.isUnhostedTest else { return }
        if #available(iOS 16.0, *) {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
}

/// Implementasi utama NotificationServiceProtocol.
/// Mengelola perizinan, penjadwalan lokal, penerimaan APNs token, manajemen badge, dan delegasi notifikasi.
public final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {
    public static let shared = NotificationService()

    private let executor: NotificationCenterExecutor
    private let delegateHandler: NotificationCenterDelegateHandler

    public init(
        delegateHandler: NotificationCenterDelegateHandler = .shared
    ) {
        self.executor = NotificationCenterExecutor()
        self.delegateHandler = delegateHandler
        setupDelegate()
    }

    internal init(
        executor: NotificationCenterExecutor,
        delegateHandler: NotificationCenterDelegateHandler = .shared
    ) {
        self.executor = executor
        self.delegateHandler = delegateHandler
    }

    private func setupDelegate() {
        // Hindari pemanggilan UNUserNotificationCenter.current() saat berjalan di unhosted XCTest bundle
        // untuk mencegah NSInternalInconsistencyException (bundleProxyForCurrentProcess is nil)
        guard NSClassFromString("XCTestCase") == nil else {
            return
        }
        UNUserNotificationCenter.current().delegate = delegateHandler
    }

    // MARK: - Authorization & APNs Token

    public func requestAuthorization(options: UNAuthorizationOptions = [.alert, .badge, .sound]) async throws -> Bool {
        try await executor.requestAuthorization(options)
    }

    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await executor.getNotificationSettings()
        return settings.authorizationStatus
    }

    public func formatDeviceToken(_ deviceToken: Data) -> String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // MARK: - Local Notification Scheduling

    public func schedule(payload: NotificationPayload, trigger: UNNotificationTrigger?) async throws {
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.subtitle = payload.subtitle
        content.body = payload.body
        content.badge = payload.badge

        if let sound = payload.sound.unSound {
            content.sound = sound
        }

        var fullUserInfo = payload.userInfo
        if let deepLinkURL = payload.deepLinkURL {
            fullUserInfo["deeplink"] = deepLinkURL.absoluteString
        }
        content.userInfo = fullUserInfo

        let request = UNNotificationRequest(
            identifier: payload.id,
            content: content,
            trigger: trigger
        )

        try await executor.add(request)
    }

    public func scheduleTimeInterval(
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
    ) async throws {
        let payload = NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            badge: badge,
            sound: sound,
            deepLinkURL: deepLinkURL,
            userInfo: userInfo
        )
        // TimeInterval trigger minimal 60 detik jika repeats = true
        let safeInterval = (repeats && timeInterval < 60) ? 60 : max(0.1, timeInterval)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: safeInterval, repeats: repeats)
        try await schedule(payload: payload, trigger: trigger)
    }

    public func scheduleCalendar(
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
    ) async throws {
        let payload = NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            badge: badge,
            sound: sound,
            deepLinkURL: deepLinkURL,
            userInfo: userInfo
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        try await schedule(payload: payload, trigger: trigger)
    }

    // MARK: - Cancellation & Querying

    public func removePending(ids: [String]) async {
        executor.removePendingNotificationRequests(ids)
    }

    public func removeAllPending() async {
        executor.removeAllPendingNotificationRequests()
    }

    public func removeDelivered(ids: [String]) async {
        executor.removeDeliveredNotifications(ids)
    }

    public func removeAllDelivered() async {
        executor.removeAllDeliveredNotifications()
    }

    public func getPendingNotificationIDs() async -> [String] {
        let requests = await executor.getPendingNotificationRequests()
        return requests.map { $0.identifier }
    }

    public func getDeliveredNotificationIDs() async -> [String] {
        let notifications = await executor.getDeliveredNotifications()
        return notifications.map { $0.request.identifier }
    }

    // MARK: - Badge Management

    public func setBadgeCount(_ count: Int) async throws {
        try await executor.setBadgeCount(count)
    }

    public func clearBadge() async throws {
        try await setBadgeCount(0)
    }

    // MARK: - Actionable Categories

    public func registerCategories(_ categories: [NotificationCategory]) async {
        let unCategories = Set(categories.map { $0.makeUNNotificationCategory() })
        executor.setNotificationCategories(unCategories)
    }

    // MARK: - Reactive Event Streaming

    public var openedNotificationPublisher: AnyPublisher<NotificationPayload, Never> {
        delegateHandler.openedPublisher
    }

    public var receivedNotificationPublisher: AnyPublisher<NotificationPayload, Never> {
        delegateHandler.receivedPublisher
    }
}
