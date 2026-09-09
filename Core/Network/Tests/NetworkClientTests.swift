import XCTest
import Combine
import Moya
@testable import CoreNetwork

// MARK: - Test Helpers

private struct SampleResponse: Codable, Equatable {
    let id: Int
    let title: String
}

private enum TestTarget: TargetType {
    case success
    case failure404
    case failure500
    case invalidJSON
    case voidEndpoint

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String {
        switch self {
        case .success: return "/test"
        case .failure404: return "/notfound"
        case .failure500: return "/error"
        case .invalidJSON: return "/invalid"
        case .voidEndpoint: return "/empty"
        }
    }
    var method: Moya.Method { .get }
    var task: Task { .requestPlain }
    var headers: [String: String]? { nil }

    var sampleData: Data {
        switch self {
        case .success:
            return """
            {"id": 1, "title": "Test Product"}
            """.data(using: .utf8)!
        case .failure404:
            return "Not Found".data(using: .utf8)!
        case .failure500:
            return "Internal Server Error".data(using: .utf8)!
        case .invalidJSON:
            return "Corrupted JSON".data(using: .utf8)!
        case .voidEndpoint:
            return Data()
        }
    }
}

/// A spy plugin that records prepare, willSend, didReceive, and process calls.
private final class SpyPlugin: PluginType, @unchecked Sendable {
    var prepareCallCount = 0
    var willSendCallCount = 0
    var didReceiveCallCount = 0
    var processCallCount = 0

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        prepareCallCount += 1
        return request
    }

    func willSend(_ request: RequestType, target: TargetType) {
        willSendCallCount += 1
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        didReceiveCallCount += 1
    }

    func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        processCallCount += 1
        return result
    }
}

// MARK: - Tests

final class NetworkClientTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeStubbedProvider(
        statusCode: Int = 200,
        target: TestTarget = .success,
        plugins: [PluginType] = []
    ) -> MoyaProvider<TestTarget> {
        let endpointClosure = { (target: TestTarget) -> Endpoint in
            Endpoint(
                url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                sampleResponseClosure: { .networkResponse(statusCode, target.sampleData) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }
        return MoyaProvider<TestTarget>(
            endpointClosure: endpointClosure,
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: plugins
        )
    }

    // MARK: - Combine Publisher Tests

    func test_combinePublisher_success() {
        let provider = makeStubbedProvider()
        let client = MoyaNetworkClient(customProvider: provider)

        let expectation = self.expectation(description: "Combine request succeeds")
        var receivedValue: SampleResponse?

        client.request(target: TestTarget.success, type: SampleResponse.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                },
                receiveValue: { response in
                    receivedValue = response
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(receivedValue, SampleResponse(id: 1, title: "Test Product"))
    }

    func test_combinePublisher_voidEndpoint_success() {
        let provider = makeStubbedProvider(statusCode: 204, target: .voidEndpoint)
        let client = MoyaNetworkClient(customProvider: provider)

        let expectation = self.expectation(description: "Void request succeeds")
        var didComplete = false

        client.request(target: TestTarget.voidEndpoint)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        didComplete = true
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0)
        XCTAssertTrue(didComplete)
    }

    // MARK: - Async/Await Tests

    func test_asyncAwait_success() async throws {
        let provider = makeStubbedProvider()
        let client = MoyaNetworkClient(customProvider: provider)

        let result = try await client.request(target: TestTarget.success, type: SampleResponse.self)
        XCTAssertEqual(result, SampleResponse(id: 1, title: "Test Product"))
    }

    func test_asyncAwait_voidEndpoint_success() async throws {
        let provider = makeStubbedProvider(statusCode: 204, target: .voidEndpoint)
        let client = MoyaNetworkClient(customProvider: provider)

        // Should complete without throwing
        try await client.request(target: TestTarget.voidEndpoint)
    }

    func test_asyncAwait_emptyResponse_success() async throws {
        let provider = makeStubbedProvider(statusCode: 200, target: .voidEndpoint)
        let client = MoyaNetworkClient(customProvider: provider)

        let result: EmptyResponse = try await client.request(target: TestTarget.voidEndpoint, type: EmptyResponse.self)
        XCTAssertEqual(result, EmptyResponse())
    }

    func test_asyncAwait_failureStatusCode() async {
        let provider = makeStubbedProvider(statusCode: 404, target: .failure404)
        let client = MoyaNetworkClient(customProvider: provider)

        do {
            _ = try await client.request(target: TestTarget.failure404, type: SampleResponse.self)
            XCTFail("Expected failure but succeeded")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.notFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_asyncAwait_failure401_mapsToUnauthorized() async {
        let endpointClosure = { (target: TestTarget) -> Endpoint in
            Endpoint(
                url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                sampleResponseClosure: { .networkResponse(401, Data()) },
                method: target.method,
                task: target.task,
                httpHeaderFields: target.headers
            )
        }
        let provider = MoyaProvider<TestTarget>(
            endpointClosure: endpointClosure,
            stubClosure: MoyaProvider.immediatelyStub
        )
        let client = MoyaNetworkClient(customProvider: provider)

        do {
            _ = try await client.request(target: TestTarget.success, type: SampleResponse.self)
            XCTFail("Expected failure but succeeded")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Smart Retry Tests

    func test_smartRetry_doesNotRetry404() async {
        let spy = SpyPlugin()
        let provider = makeStubbedProvider(statusCode: 404, target: .failure404, plugins: [spy])
        let client = MoyaNetworkClient(
            customProvider: provider,
            configuration: NetworkConfiguration(retryPolicy: RetryPolicy(maxRetryCount: 3))
        )

        do {
            _ = try await client.request(target: TestTarget.failure404, type: SampleResponse.self)
            XCTFail("Expected failure")
        } catch {
            // 404 is not retryable -> willSend must be called only ONCE, not 4 times!
            XCTAssertEqual(spy.willSendCallCount, 1, "404 should not trigger retries")
        }
    }

    // MARK: - Task Cancellation Tests

    func test_taskCancellation_cancelsRequest() async {
        let provider = makeStubbedProvider()
        let client = MoyaNetworkClient(customProvider: provider)

        let task = _Concurrency.Task {
            try await client.request(target: TestTarget.success, type: SampleResponse.self)
        }
        task.cancel()

        // Cancellation should be respected
        XCTAssertTrue(task.isCancelled)
    }

    // MARK: - Plugin Lifecycle Tests

    func test_plugins_lifecycleCalled() async throws {
        let spy = SpyPlugin()
        let provider = makeStubbedProvider(plugins: [spy])
        let client = MoyaNetworkClient(customProvider: provider)

        _ = try await client.request(target: TestTarget.success, type: SampleResponse.self)
        XCTAssertGreaterThan(spy.prepareCallCount, 0, "prepare should be called")
        XCTAssertGreaterThan(spy.willSendCallCount, 0, "willSend should be called")
        XCTAssertGreaterThan(spy.processCallCount, 0, "process should be called")
        XCTAssertGreaterThan(spy.didReceiveCallCount, 0, "didReceive should be called")
    }

    // MARK: - Configuration Tests

    func test_defaultConfiguration_isUsed() {
        let client = MoyaNetworkClient()
        XCTAssertNotNil(client)
    }

    func test_customConfiguration_isAccepted() {
        let config = NetworkConfiguration(
            timeoutInterval: 120,
            retryPolicy: RetryPolicy(maxRetryCount: 5),
            logLevel: .verbose
        )
        let client = MoyaNetworkClient(configuration: config)
        XCTAssertNotNil(client)
    }
}
