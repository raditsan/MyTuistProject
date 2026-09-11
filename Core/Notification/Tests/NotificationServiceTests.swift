import XCTest
import Combine
import FactoryKit
import UserNotifications
@testable import CoreNotification

final class NotificationServiceTests: XCTestCase {
    private final class MockNotificationBox: @unchecked Sendable {
        var addedRequests: [UNNotificationRequest] = []
        var requestedOptions: UNAuthorizationOptions?
        var authResult: Bool = true
        var authError: Error?
        var recordedBadge: Int = 0
        var registeredCategories: Set<UNNotificationCategory> = []
    }

    private var box: MockNotificationBox!
    private var mockExecutor: NotificationCenterExecutor!
    private var sut: NotificationService!

    override func setUp() {
        super.setUp()
        box = MockNotificationBox()
        var executor = NotificationCenterExecutor()

        executor.requestAuthorization = { [weak box] options in
            box?.requestedOptions = options
            if let error = box?.authError {
                throw error
            }
            return box?.authResult ?? true
        }

        executor.add = { [weak box] request in
            box?.addedRequests.append(request)
        }

        executor.getPendingNotificationRequests = { [weak box] in
            box?.addedRequests ?? []
        }

        executor.removePendingNotificationRequests = { [weak box] identifiers in
            box?.addedRequests.removeAll { identifiers.contains($0.identifier) }
        }

        executor.removeAllPendingNotificationRequests = { [weak box] in
            box?.addedRequests.removeAll()
        }

        executor.removeDeliveredNotifications = { [weak box] identifiers in
            box?.addedRequests.removeAll { identifiers.contains($0.identifier) }
        }

        executor.removeAllDeliveredNotifications = { [weak box] in
            box?.addedRequests.removeAll()
        }

        executor.getDeliveredNotifications = {
            []
        }

        executor.setBadgeCount = { [weak box] count in
            box?.recordedBadge = count
        }

        executor.setNotificationCategories = { [weak box] categories in
            box?.registeredCategories = categories
        }

        self.mockExecutor = executor
        self.sut = NotificationService(executor: executor)
    }

    override func tearDown() {
        box = nil
        mockExecutor = nil
        sut = nil
        super.tearDown()
    }

    func test_requestAuthorization_success() async throws {
        let granted = try await sut.requestAuthorization(options: [.alert, .sound])
        XCTAssertTrue(granted)
        XCTAssertEqual(box.requestedOptions, [.alert, .sound])

        // Test default options helper
        let grantedDefault = try await sut.requestAuthorization()
        XCTAssertTrue(grantedDefault)
        XCTAssertEqual(box.requestedOptions, [.alert, .badge, .sound])
    }

    func test_requestAuthorization_failure() async {
        struct MockError: Error, Equatable {}
        box.authError = MockError()

        do {
            _ = try await sut.requestAuthorization()
            XCTFail("Harus melempar error")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    func test_scheduleTimeInterval_createsRequestWithProperContent() async throws {
        let notifId = "time-interval-notif-1"
        let deepLink = URL(string: "mytuist://product/101")!

        try await sut.scheduleTimeInterval(
            id: notifId,
            title: "Flash Sale!",
            subtitle: "Berakhir 1 Jam Lagi",
            body: "Cek produk pilihanmu sekarang.",
            timeInterval: 120,
            repeats: false,
            userInfo: ["campaign": "flash_sale"],
            deepLinkURL: deepLink,
            sound: .defaultSound,
            badge: 1
        )

        XCTAssertEqual(box.addedRequests.count, 1)
        let request = try XCTUnwrap(box.addedRequests.first)
        XCTAssertEqual(request.identifier, notifId)
        XCTAssertEqual(request.content.title, "Flash Sale!")
        XCTAssertEqual(request.content.subtitle, "Berakhir 1 Jam Lagi")
        XCTAssertEqual(request.content.body, "Cek produk pilihanmu sekarang.")
        XCTAssertEqual(request.content.badge, 1)
        XCTAssertEqual(request.content.userInfo["campaign"] as? String, "flash_sale")
        XCTAssertEqual(request.content.userInfo["deeplink"] as? String, "mytuist://product/101")
        XCTAssertTrue(request.trigger is UNTimeIntervalNotificationTrigger)
    }

    func test_scheduleCalendar_createsRequestWithCalendarTrigger() async throws {
        let notifId = "calendar-notif-1"
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        try await sut.scheduleCalendar(
            id: notifId,
            title: "Pengingat Pagi",
            body: "Lihat promo hari ini",
            dateComponents: dateComponents,
            repeats: true
        )

        XCTAssertEqual(box.addedRequests.count, 1)
        let request = try XCTUnwrap(box.addedRequests.first)
        XCTAssertEqual(request.identifier, notifId)
        XCTAssertEqual(request.content.title, "Pengingat Pagi")
        XCTAssertTrue(request.trigger is UNCalendarNotificationTrigger)
    }

    func test_cancellation_and_querying() async throws {
        try await sut.scheduleTimeInterval(id: "notif-1", title: "T1", body: "B1", timeInterval: 5)
        try await sut.scheduleTimeInterval(id: "notif-2", title: "T2", body: "B2", timeInterval: 10)
        try await sut.scheduleTimeInterval(id: "notif-3", title: "T3", body: "B3", timeInterval: 15)

        var pendingIds = await sut.getPendingNotificationIDs()
        XCTAssertEqual(pendingIds.count, 3)

        // Remove single
        await sut.removePending(ids: ["notif-2"])
        pendingIds = await sut.getPendingNotificationIDs()
        XCTAssertEqual(pendingIds, ["notif-1", "notif-3"])

        // Remove delivered
        await sut.removeDelivered(ids: ["notif-1"])
        let remaining = await sut.getPendingNotificationIDs()
        XCTAssertEqual(remaining, ["notif-3"])

        // Remove all
        await sut.removeAllPending()
        let emptyPending = await sut.getPendingNotificationIDs()
        XCTAssertTrue(emptyPending.isEmpty)

        await sut.removeAllDelivered()
        let emptyDelivered = await sut.getDeliveredNotificationIDs()
        XCTAssertTrue(emptyDelivered.isEmpty)
    }

    func test_badgeManagement() async throws {
        try await sut.setBadgeCount(5)
        XCTAssertEqual(box.recordedBadge, 5)

        try await sut.clearBadge()
        XCTAssertEqual(box.recordedBadge, 0)
    }

    func test_registerCategories() async {
        let action = NotificationAction(identifier: "CONFIRM", title: "Konfirmasi")
        let category = NotificationCategory(identifier: "ACTION_CATEGORY", actions: [action])

        await sut.registerCategories([category])
        XCTAssertEqual(box.registeredCategories.count, 1)
        XCTAssertEqual(box.registeredCategories.first?.identifier, "ACTION_CATEGORY")
    }

    func test_container_dependencyInjection() {
        let service = Container.shared.notificationService()
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.receivedNotificationPublisher)
    }
}
