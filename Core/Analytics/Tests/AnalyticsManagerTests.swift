import XCTest
import FactoryKit
@testable import CoreAnalytics

// MARK: - Mock Analytics Provider
final class MockAnalyticsProvider: AnalyticsProviderProtocol, @unchecked Sendable {
    let name: String
    var isEnabled: Bool

    var isInitialized = false
    var isResetCalled = false
    var loggedEvents: [AnalyticsEvent] = []
    var userId: String?
    var userProperties: [String: String?] = [:]

    init(name: String, isEnabled: Bool = true) {
        self.name = name
        self.isEnabled = isEnabled
    }

    func initialize() {
        isInitialized = true
    }

    func logEvent(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }

    func setUserId(_ userId: String?) {
        self.userId = userId
    }

    func setUserProperty(name: String, value: String?) {
        userProperties[name] = value
    }

    func reset() {
        isResetCalled = true
        userId = nil
        userProperties.removeAll()
    }
}

// MARK: - AnalyticsManagerTests
final class AnalyticsManagerTests: XCTestCase {
    private var mockFirebase: MockAnalyticsProvider!
    private var mockMoEngage: MockAnalyticsProvider!
    private var mockDynatrace: MockAnalyticsProvider!
    private var sut: AnalyticsManager!

    override func setUp() {
        super.setUp()
        mockFirebase = MockAnalyticsProvider(name: "Firebase")
        mockMoEngage = MockAnalyticsProvider(name: "MoEngage")
        mockDynatrace = MockAnalyticsProvider(name: "Dynatrace")
        sut = AnalyticsManager(providers: [mockFirebase, mockMoEngage, mockDynatrace])
    }

    override func tearDown() {
        sut = nil
        mockFirebase = nil
        mockMoEngage = nil
        mockDynatrace = nil
        super.tearDown()
    }

    func test_initialize_callsAllEnabledProviders() {
        sut.initialize()

        XCTAssertTrue(mockFirebase.isInitialized)
        XCTAssertTrue(mockMoEngage.isInitialized)
        XCTAssertTrue(mockDynatrace.isInitialized)
    }

    func test_logEvent_dispatchesToAllEnabledProviders() {
        let params: [String: Any] = ["item_id": "123", "price": 99.9]
        sut.logEvent("purchase", parameters: params)

        XCTAssertEqual(mockFirebase.loggedEvents.count, 1)
        XCTAssertEqual(mockFirebase.loggedEvents.first?.name, "purchase")
        XCTAssertEqual(mockFirebase.loggedEvents.first?.parameters?["item_id"] as? String, "123")

        XCTAssertEqual(mockMoEngage.loggedEvents.count, 1)
        XCTAssertEqual(mockMoEngage.loggedEvents.first?.name, "purchase")

        XCTAssertEqual(mockDynatrace.loggedEvents.count, 1)
        XCTAssertEqual(mockDynatrace.loggedEvents.first?.name, "purchase")
    }

    func test_disabledProvider_doesNotReceiveEvents() {
        mockMoEngage.isEnabled = false

        sut.logEvent("click_button")

        XCTAssertEqual(mockFirebase.loggedEvents.count, 1)
        XCTAssertEqual(mockMoEngage.loggedEvents.count, 0)
        XCTAssertEqual(mockDynatrace.loggedEvents.count, 1)
    }

    func test_setUserId_dispatchesToAllProviders() {
        sut.setUserId("user_001")

        XCTAssertEqual(mockFirebase.userId, "user_001")
        XCTAssertEqual(mockMoEngage.userId, "user_001")
        XCTAssertEqual(mockDynatrace.userId, "user_001")
    }

    func test_setUserProperty_dispatchesToAllProviders() {
        sut.setUserProperty(name: "user_tier", value: "platinum")

        XCTAssertEqual(mockFirebase.userProperties["user_tier"], "platinum")
        XCTAssertEqual(mockMoEngage.userProperties["user_tier"], "platinum")
        XCTAssertEqual(mockDynatrace.userProperties["user_tier"], "platinum")
    }

    func test_reset_dispatchesToAllProviders() {
        sut.setUserId("user_001")
        sut.reset()

        XCTAssertTrue(mockFirebase.isResetCalled)
        XCTAssertNil(mockFirebase.userId)
        XCTAssertTrue(mockMoEngage.isResetCalled)
        XCTAssertNil(mockMoEngage.userId)
        XCTAssertTrue(mockDynatrace.isResetCalled)
        XCTAssertNil(mockDynatrace.userId)
    }

    func test_registerAndRemoveProvider() {
        let customProvider = MockAnalyticsProvider(name: "CustomMixpanel")
        sut.register(provider: customProvider)

        XCTAssertNotNil(sut.getProvider(named: "CustomMixpanel"))
        XCTAssertEqual(sut.providers.count, 4)

        sut.removeProvider(named: "CustomMixpanel")
        XCTAssertNil(sut.getProvider(named: "CustomMixpanel"))
        XCTAssertEqual(sut.providers.count, 3)
    }

    func test_logScreenView_createsCorrectEvent() {
        sut.logScreenView(screenName: "ProductDetail", screenClass: "ProductDetailView")

        XCTAssertEqual(mockFirebase.loggedEvents.count, 1)
        let event = mockFirebase.loggedEvents.first
        XCTAssertEqual(event?.name, "screen_view")
        XCTAssertEqual(event?.parameters?["screen_name"] as? String, "ProductDetail")
        XCTAssertEqual(event?.parameters?["screen_class"] as? String, "ProductDetailView")
    }

    func test_consoleAnalyticsProvider_executesWithoutError() {
        let console = ConsoleAnalyticsProvider()

        console.initialize()
        console.logEvent(AnalyticsEvent(name: "test_event", parameters: ["foo": "bar"]))
        console.setUserId("123")
        console.setUserProperty(name: "role", value: "admin")
        console.reset()

        XCTAssertEqual(console.name, "Console")
        XCTAssertTrue(console.isEnabled)
    }

    func test_containerAnalyticsResolution() {
        let manager = Container.shared.analytics()
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.providers.count, 1)
        XCTAssertEqual(manager.providers.first?.name, "Console")
    }
}
