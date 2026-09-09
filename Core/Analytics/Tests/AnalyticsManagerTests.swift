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
    var recordedErrors: [(error: Error, parameters: [String: Any]?)] = []

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

    func recordError(_ error: Error, additionalParameters: [String: Any]?) {
        recordedErrors.append((error, additionalParameters))
    }

    func reset() {
        isResetCalled = true
        userId = nil
        userProperties.removeAll()
        recordedErrors.removeAll()
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
        sut = AnalyticsManager(
            providers: [mockFirebase, mockMoEngage, mockDynatrace],
            isAutomaticMetadataEnabled: true
        )
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

    func test_logEvent_dispatchesToAllEnabledProvidersWithMetadata() {
        let params: [String: Any] = ["item_id": "123", "price": 99.9]
        sut.logEvent("purchase", parameters: params)

        XCTAssertEqual(mockFirebase.loggedEvents.count, 1)
        let event = mockFirebase.loggedEvents.first
        XCTAssertEqual(event?.name, "purchase")
        XCTAssertEqual(event?.parameters?["item_id"] as? String, "123")
        XCTAssertEqual(event?.parameters?["platform"] as? String, "iOS")
        XCTAssertNotNil(event?.parameters?["os_version"])
        XCTAssertNotNil(event?.parameters?["device_model"])

        XCTAssertEqual(mockMoEngage.loggedEvents.count, 1)
        XCTAssertEqual(mockDynatrace.loggedEvents.count, 1)
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

    func test_customGlobalParameters_injectedIntoEvents() {
        sut.setGlobalParameter(name: "app_theme", value: "dark")
        sut.setGlobalParameter(name: "network_status", value: "wifi")

        sut.logEvent("test_event", parameters: ["local_key": "local_val"])

        let event = mockFirebase.loggedEvents.first
        XCTAssertEqual(event?.parameters?["app_theme"] as? String, "dark")
        XCTAssertEqual(event?.parameters?["network_status"] as? String, "wifi")
        XCTAssertEqual(event?.parameters?["local_key"] as? String, "local_val")

        sut.removeGlobalParameter(name: "network_status")
        sut.clearGlobalParameters()
    }

    func test_disableAutomaticMetadata() {
        sut.isAutomaticMetadataEnabled = false
        sut.logEvent("plain_event", parameters: ["foo": "bar"])

        let event = mockFirebase.loggedEvents.first
        XCTAssertEqual(event?.parameters?["foo"] as? String, "bar")
        XCTAssertNil(event?.parameters?["platform"])
        XCTAssertNil(event?.parameters?["os_version"])
    }

    func test_recordError_dispatchesToAllProviders() {
        enum TestError: LocalizedError {
            case networkFailed
            var errorDescription: String? { "Network request failed" }
        }

        sut.recordError(TestError.networkFailed, additionalParameters: ["endpoint": "/products"])

        XCTAssertEqual(mockFirebase.recordedErrors.count, 1)
        let recorded = mockFirebase.recordedErrors.first
        XCTAssertEqual(recorded?.error.localizedDescription, "Network request failed")
        XCTAssertEqual(recorded?.parameters?["endpoint"] as? String, "/products")
        XCTAssertEqual(recorded?.parameters?["platform"] as? String, "iOS")

        sut.recordError("Simple crash message", additionalParameters: ["tag": "fatal"])
        XCTAssertEqual(mockFirebase.recordedErrors.count, 2)
    }

    func test_ecommerceEventTaxonomy() {
        let viewItem = AnalyticsEvent.viewItem(id: "P1", name: "Shoe", price: 150000, category: "Fashion")
        XCTAssertEqual(viewItem.name, "view_item")
        XCTAssertEqual(viewItem.parameters?["item_id"] as? String, "P1")
        XCTAssertEqual(viewItem.parameters?["item_category"] as? String, "Fashion")

        let viewItemList = AnalyticsEvent.viewItemList(category: "Electronics", itemsCount: 10)
        XCTAssertEqual(viewItemList.name, "view_item_list")
        XCTAssertEqual(viewItemList.parameters?["items_count"] as? Int, 10)

        let addToCart = AnalyticsEvent.addToCart(id: "P1", name: "Shoe", price: 150000, quantity: 2)
        XCTAssertEqual(addToCart.name, "add_to_cart")
        XCTAssertEqual(addToCart.parameters?["quantity"] as? Int, 2)

        let removeFromCart = AnalyticsEvent.removeFromCart(id: "P1", name: "Shoe", price: 150000)
        XCTAssertEqual(removeFromCart.name, "remove_from_cart")

        let beginCheckout = AnalyticsEvent.beginCheckout(value: 300000, itemsCount: 2)
        XCTAssertEqual(beginCheckout.name, "begin_checkout")
        XCTAssertEqual(beginCheckout.parameters?["value"] as? Double, 300000)

        let purchase = AnalyticsEvent.purchase(orderId: "ORD-123", value: 300000, itemsCount: 2)
        XCTAssertEqual(purchase.name, "purchase")
        XCTAssertEqual(purchase.parameters?["transaction_id"] as? String, "ORD-123")

        let search = AnalyticsEvent.search(query: "Sneakers")
        XCTAssertEqual(search.name, "search")
        XCTAssertEqual(search.parameters?["search_term"] as? String, "Sneakers")
    }

    func test_consoleAnalyticsProvider_executesWithoutError() {
        let console = ConsoleAnalyticsProvider()

        console.initialize()
        console.logEvent(AnalyticsEvent(name: "test_event", parameters: ["foo": "bar"]))
        console.setUserId("123")
        console.setUserProperty(name: "role", value: "admin")
        console.recordError(SimpleAnalyticsError(message: "test error"), additionalParameters: ["code": 500])
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
