import XCTest
import Moya
@testable import CoreNetwork

// MARK: - Test Helpers

private enum MockTarget: TargetType {
    case getItems

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/items" }
    var method: Moya.Method { .get }
    var task: Task { .requestPlain }
    var headers: [String: String]? { ["Custom-Header": "TestValue"] }
    var sampleData: Data { "{\"status\":\"ok\"}".data(using: .utf8)! }
}

private enum AuthMockTarget: TargetType, AuthenticatableEndpoint {
    case authenticated
    case publicEndpoint

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/test" }
    var method: Moya.Method { .get }
    var task: Task { .requestPlain }
    var headers: [String: String]? { nil }
    var sampleData: Data { Data() }

    var requiresAuth: Bool {
        switch self {
        case .authenticated: return true
        case .publicEndpoint: return false
        }
    }
}

// MARK: - LoggingPlugin Tests

final class LoggingPluginTests: XCTestCase {

    func test_loggingPlugin_verbose_executesWithoutCrash() {
        let plugin = LoggingPlugin(logLevel: .verbose)
        let provider = MoyaProvider<MockTarget>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [plugin]
        )

        let expectation = self.expectation(description: "Request completes")
        provider.request(.getItems) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_loggingPlugin_standard_executesWithoutCrash() {
        let plugin = LoggingPlugin(logLevel: .standard)
        let provider = MoyaProvider<MockTarget>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [plugin]
        )

        let expectation = self.expectation(description: "Request completes")
        provider.request(.getItems) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_loggingPlugin_minimal_executesWithoutCrash() {
        let plugin = LoggingPlugin(logLevel: .minimal)
        let provider = MoyaProvider<MockTarget>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [plugin]
        )

        let expectation = self.expectation(description: "Request completes")
        provider.request(.getItems) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_loggingPlugin_none_executesWithoutCrash() {
        let plugin = LoggingPlugin(logLevel: .none)
        let provider = MoyaProvider<MockTarget>(
            stubClosure: MoyaProvider.immediatelyStub,
            plugins: [plugin]
        )

        let expectation = self.expectation(description: "Request completes")
        provider.request(.getItems) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func test_loggingPlugin_didReceiveFailure_doesNotCrash() {
        let plugin = LoggingPlugin(logLevel: .minimal)
        let error = MoyaError.statusCode(Response(statusCode: 500, data: Data()))
        let result: Result<Response, MoyaError> = .failure(error)

        plugin.didReceive(result, target: MockTarget.getItems)
    }
}

// MARK: - AuthPlugin Tests

final class AuthPluginTests: XCTestCase {

    func test_prepare_injectsAuthHeader() {
        let tokenProvider = StaticTokenProvider(token: "my-secret-token")
        let plugin = AuthPlugin(tokenProvider: tokenProvider)

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "Authorization"), "Bearer my-secret-token")
    }

    func test_prepare_skipsAuthWhenTokenIsNil() {
        let tokenProvider = StaticTokenProvider(token: nil)
        let plugin = AuthPlugin(tokenProvider: tokenProvider)

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertNil(prepared.value(forHTTPHeaderField: "Authorization"))
    }

    func test_prepare_skipsAuthWhenTokenIsEmpty() {
        let tokenProvider = StaticTokenProvider(token: "")
        let plugin = AuthPlugin(tokenProvider: tokenProvider)

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertNil(prepared.value(forHTTPHeaderField: "Authorization"))
    }

    func test_prepare_skipsAuthForPublicEndpoint() {
        let tokenProvider = StaticTokenProvider(token: "my-secret-token")
        let plugin = AuthPlugin(tokenProvider: tokenProvider)

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: AuthMockTarget.publicEndpoint)

        XCTAssertNil(prepared.value(forHTTPHeaderField: "Authorization"))
    }

    func test_prepare_injectsAuthForAuthenticatedEndpoint() {
        let tokenProvider = StaticTokenProvider(token: "my-secret-token")
        let plugin = AuthPlugin(tokenProvider: tokenProvider)

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: AuthMockTarget.authenticated)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "Authorization"), "Bearer my-secret-token")
    }

    func test_prepare_customScheme() {
        let tokenProvider = StaticTokenProvider(token: "api-key-123")
        let plugin = AuthPlugin(tokenProvider: tokenProvider, scheme: "ApiKey")

        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "Authorization"), "ApiKey api-key-123")
    }
}

// MARK: - ErrorPlugin Tests

final class ErrorPluginTests: XCTestCase {

    private final class MockErrorHandler: NetworkErrorHandler, @unchecked Sendable {
        var handledErrors: [NetworkError] = []

        func handleError(_ error: NetworkError, for target: any TargetType) {
            handledErrors.append(error)
        }
    }

    func test_didReceive_success_doesNotCallHandler() {
        let handler = MockErrorHandler()
        let plugin = ErrorPlugin(errorHandler: handler)
        let response = Response(statusCode: 200, data: Data())
        let result: Result<Response, MoyaError> = .success(response)

        plugin.didReceive(result, target: MockTarget.getItems)

        XCTAssertTrue(handler.handledErrors.isEmpty)
    }

    func test_didReceive_failure_callsErrorHandler() {
        let handler = MockErrorHandler()
        let plugin = ErrorPlugin(errorHandler: handler)
        let error = MoyaError.statusCode(Response(statusCode: 401, data: Data()))
        let result: Result<Response, MoyaError> = .failure(error)

        plugin.didReceive(result, target: MockTarget.getItems)

        XCTAssertEqual(handler.handledErrors.count, 1)
        XCTAssertEqual(handler.handledErrors.first, .unauthorized)
    }

    func test_didReceive_noHandler_doesNotCrash() {
        let plugin = ErrorPlugin(errorHandler: nil)
        let error = MoyaError.statusCode(Response(statusCode: 500, data: Data()))
        let result: Result<Response, MoyaError> = .failure(error)

        plugin.didReceive(result, target: MockTarget.getItems)
    }
}

// MARK: - RetryPlugin Tests

final class RetryPluginTests: XCTestCase {

    func test_process_retryableStatusCode_convertsToFailure() {
        let plugin = RetryPlugin(retryPolicy: RetryPolicy(retryableStatusCodes: [500, 502]))
        let response = Response(statusCode: 500, data: Data())
        let result: Result<Response, MoyaError> = .success(response)

        let output = plugin.process(result, target: MockTarget.getItems)
        if case .failure(let error) = output {
            if case .statusCode(let r) = error {
                XCTAssertEqual(r.statusCode, 500)
            } else {
                XCTFail("Expected statusCode MoyaError")
            }
        } else {
            XCTFail("Expected failure for retryable status code")
        }
    }

    func test_process_nonRetryableStatusCode_passesThrough() {
        let plugin = RetryPlugin(retryPolicy: RetryPolicy(retryableStatusCodes: [500]))
        let response = Response(statusCode: 404, data: Data())
        let result: Result<Response, MoyaError> = .success(response)

        let output = plugin.process(result, target: MockTarget.getItems)
        if case .success(let r) = output {
            XCTAssertEqual(r.statusCode, 404)
        } else {
            XCTFail("Expected success pass-through for non-retryable code")
        }
    }

    func test_process_failure_passesThrough() {
        let plugin = RetryPlugin()
        let error = MoyaError.underlying(NSError(domain: "test", code: -1), nil)
        let result: Result<Response, MoyaError> = .failure(error)

        let output = plugin.process(result, target: MockTarget.getItems)
        if case .failure = output {
            // Expected
        } else {
            XCTFail("Expected failure pass-through")
        }
    }

    func test_policy_property() {
        let policy = RetryPolicy(maxRetryCount: 5, retryDelay: 2.0, retryableStatusCodes: [503])
        let plugin = RetryPlugin(retryPolicy: policy)

        XCTAssertEqual(plugin.policy.maxRetryCount, 5)
        XCTAssertEqual(plugin.policy.retryDelay, 2.0)
        XCTAssertTrue(plugin.policy.retryableStatusCodes.contains(503))
    }
}

// MARK: - NetworkConfiguration Tests

final class NetworkConfigurationTests: XCTestCase {

    func test_defaultConfiguration() {
        let config = NetworkConfiguration.default
        XCTAssertEqual(config.timeoutInterval, 30)
        XCTAssertEqual(config.retryPolicy.maxRetryCount, 2)
        XCTAssertEqual(config.logLevel, .standard)
    }

    func test_developmentConfiguration() {
        let config = NetworkConfiguration.development
        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertEqual(config.logLevel, .verbose)
    }

    func test_productionConfiguration() {
        let config = NetworkConfiguration.production
        XCTAssertEqual(config.timeoutInterval, 30)
        XCTAssertEqual(config.logLevel, .none)
    }

    func test_customConfiguration() {
        let config = NetworkConfiguration(
            timeoutInterval: 120,
            retryPolicy: RetryPolicy(maxRetryCount: 5),
            logLevel: .minimal
        )
        XCTAssertEqual(config.timeoutInterval, 120)
        XCTAssertEqual(config.retryPolicy.maxRetryCount, 5)
        XCTAssertEqual(config.logLevel, .minimal)
    }
}

// MARK: - RetryPolicy Tests

final class RetryPolicyTests: XCTestCase {

    func test_nonePolicy() {
        let policy = RetryPolicy.none
        XCTAssertEqual(policy.maxRetryCount, 0)
    }

    func test_defaultPolicy() {
        let policy = RetryPolicy.default
        XCTAssertEqual(policy.maxRetryCount, 2)
        XCTAssertEqual(policy.retryDelay, 1.0)
        XCTAssertTrue(policy.retryableStatusCodes.contains(500))
        XCTAssertTrue(policy.retryableStatusCodes.contains(502))
        XCTAssertTrue(policy.retryableStatusCodes.contains(503))
        XCTAssertTrue(policy.retryableStatusCodes.contains(504))
    }
}

// MARK: - LogLevel Tests

final class LogLevelTests: XCTestCase {

    func test_logLevel_ordering() {
        XCTAssertTrue(LogLevel.none < LogLevel.minimal)
        XCTAssertTrue(LogLevel.minimal < LogLevel.standard)
        XCTAssertTrue(LogLevel.standard < LogLevel.verbose)
    }
}

// MARK: - HeaderPlugin Tests

final class HeaderPluginTests: XCTestCase {

    func test_prepare_injectsCustomHeaders() {
        let plugin = HeaderPlugin(headers: [
            "X-Platform": "iOS",
            "X-Custom": "CustomValue"
        ])
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "X-Platform"), "iOS")
        XCTAssertEqual(prepared.value(forHTTPHeaderField: "X-Custom"), "CustomValue")
    }

    func test_prepare_doesNotOverwriteExistingHeader() {
        let plugin = HeaderPlugin(headers: ["Custom-Header": "PluginValue"])
        var request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        request.setValue("EndpointValue", forHTTPHeaderField: "Custom-Header")

        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "Custom-Header"), "EndpointValue")
    }

    func test_defaultAppMetadata_containsPlatform() {
        let plugin = HeaderPlugin.defaultAppMetadata
        let request = URLRequest(url: URL(string: "https://api.example.com/test")!)
        let prepared = plugin.prepare(request, target: MockTarget.getItems)

        XCTAssertEqual(prepared.value(forHTTPHeaderField: "X-Platform"), "iOS")
    }
}

