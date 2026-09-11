import XCTest
import Combine
import UserNotifications
@testable import CoreNotification

final class NotificationDelegateHandlerTests: XCTestCase {
    private var sut: NotificationCenterDelegateHandler!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = NotificationCenterDelegateHandler()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    func test_handleWillPresent_emitsReceivedEvent_and_invokesCallback() {
        let expectationCallback = expectation(description: "Callback onNotificationReceived dipanggil")
        let expectationPublisher = expectation(description: "Publisher receivedPublisher memancarkan event")
        let expectationCompletion = expectation(description: "Completion handler dipanggil")

        let expectedPayload = NotificationPayload(
            id: "notif-foreground-1",
            title: "Ada Pesan Baru",
            body: "Halo dari foreground!"
        )

        // 1. Subscribe ke Combine Publisher
        sut.receivedPublisher
            .sink { payload in
                XCTAssertEqual(payload, expectedPayload)
                expectationPublisher.fulfill()
            }
            .store(in: &cancellables)

        // 2. Pasang Closure Callback
        sut.onNotificationReceived = { payload in
            XCTAssertEqual(payload, expectedPayload)
            expectationCallback.fulfill()
        }

        // 3. Simulasikan pemanggilan willPresent
        sut.handleWillPresent(payload: expectedPayload) { options in
            XCTAssertEqual(options, self.sut.foregroundPresentationOptions)
            expectationCompletion.fulfill()
        }

        wait(for: [expectationCallback, expectationPublisher, expectationCompletion], timeout: 2.0)
    }

    func test_handleDidReceive_emitsOpenedEvent_and_invokesCallback() {
        let expectationCallback = expectation(description: "Callback onNotificationOpened dipanggil")
        let expectationPublisher = expectation(description: "Publisher openedPublisher memancarkan event")
        let expectationCompletion = expectation(description: "Completion handler dipanggil")

        let expectedPayload = NotificationPayload(
            id: "notif-tap-1",
            title: "Promo Spesial",
            body: "Klik untuk buka detail",
            deepLinkURL: URL(string: "mytuist://product/55"),
            actionIdentifier: "UNNotificationDefaultActionIdentifier"
        )

        // 1. Subscribe ke Combine Publisher
        sut.openedPublisher
            .sink { payload in
                XCTAssertEqual(payload, expectedPayload)
                XCTAssertEqual(payload.deepLinkURL?.absoluteString, "mytuist://product/55")
                XCTAssertEqual(payload.actionIdentifier, "UNNotificationDefaultActionIdentifier")
                expectationPublisher.fulfill()
            }
            .store(in: &cancellables)

        // 2. Pasang Closure Callback
        sut.onNotificationOpened = { payload in
            XCTAssertEqual(payload, expectedPayload)
            expectationCallback.fulfill()
        }

        // 3. Simulasikan pemanggilan didReceive
        sut.handleDidReceive(payload: expectedPayload) {
            expectationCompletion.fulfill()
        }

        wait(for: [expectationCallback, expectationPublisher, expectationCompletion], timeout: 2.0)
    }

    func test_service_eventStreaming_delegatesProperly() {
        let service = NotificationService(delegateHandler: sut)
        let expectation = expectation(description: "Service opened publisher memancarkan data")

        let payload = NotificationPayload(id: "stream-test", title: "T", body: "B")

        service.openedNotificationPublisher
            .sink { received in
                XCTAssertEqual(received.id, "stream-test")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.handleDidReceive(payload: payload) {}

        wait(for: [expectation], timeout: 2.0)
    }
}
