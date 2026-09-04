import XCTest
import CoreNavigation
import FactoryKit
@testable import FeatureDeeplinkLoader

private final class MockDeeplinkFlow: DeeplinkFlow {
    var shouldFail: Bool = false
    var executionCount = 0

    func execute(update: @escaping DeeplinkFlowUpdate) async {
        executionCount += 1
        update(.setLoading(true, message: "Testing..."))

        if shouldFail {
            update(.setLoading(false, message: nil))
            update(.setError("Mock Error"))
        } else {
            update(.setLoading(false, message: nil))
            update(.setError(nil))
        }
    }
}

@MainActor
final class DeeplinkLoaderViewModelTests: XCTestCase {
    private var mockFlow: MockDeeplinkFlow!
    private var sut: DeeplinkLoaderViewModel!

    override func setUp() {
        super.setUp()
        mockFlow = MockDeeplinkFlow()
        sut = DeeplinkLoaderViewModel(flow: mockFlow)
    }

    override func tearDown() {
        sut = nil
        mockFlow = nil
        super.tearDown()
    }

    func test_initialState() {
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_execute_whenSuccess_clearsLoadingAndError() async {
        mockFlow.shouldFail = false

        await sut.execute()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockFlow.executionCount, 1)
    }

    func test_execute_whenFails_setsErrorMessage() async {
        mockFlow.shouldFail = true

        await sut.execute()

        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Mock Error")
        XCTAssertEqual(mockFlow.executionCount, 1)
    }
}
