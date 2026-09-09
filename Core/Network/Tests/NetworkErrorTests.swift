import XCTest
import Moya
@testable import CoreNetwork

private struct SampleBackendError: Decodable, Equatable {
    let code: String
    let message: String
}

final class NetworkErrorTests: XCTestCase {

    // MARK: - Error Descriptions

    func test_allErrorDescriptions_areNotEmpty() {
        let errors: [NetworkError] = [
            .invalidURL,
            .invalidResponse(statusCode: 500),
            .decodingError("corrupted JSON"),
            .serverError("500 Internal"),
            .noData,
            .unknown("something broke"),
            .unauthorized,
            .forbidden,
            .notFound,
            .rateLimited,
            .timeout,
            .noInternet,
            .apiError(statusCode: 422, message: "Validation error", data: nil)
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty, "Description should not be empty for \(error)")
        }
    }

    // MARK: - Status Code Mapping

    func test_fromStatusCode_401_mapsToUnauthorized() {
        XCTAssertEqual(NetworkError.fromStatusCode(401), .unauthorized)
    }

    func test_fromStatusCode_403_mapsToForbidden() {
        XCTAssertEqual(NetworkError.fromStatusCode(403), .forbidden)
    }

    func test_fromStatusCode_404_mapsToNotFound() {
        XCTAssertEqual(NetworkError.fromStatusCode(404), .notFound)
    }

    func test_fromStatusCode_429_mapsToRateLimited() {
        XCTAssertEqual(NetworkError.fromStatusCode(429), .rateLimited)
    }

    func test_fromStatusCode_500_mapsToInvalidResponse() {
        XCTAssertEqual(NetworkError.fromStatusCode(500), .invalidResponse(statusCode: 500))
    }

    // MARK: - Backend Error Extraction Tests

    func test_fromResponse_extractsJSONMessage() {
        let json = "{\"message\":\"Email already taken\",\"code\":\"EMAIL_EXISTS\"}".data(using: .utf8)!
        let response = Response(statusCode: 400, data: json)
        let error = NetworkError.fromResponse(response)

        if case .apiError(let code, let message, _) = error {
            XCTAssertEqual(code, 400)
            XCTAssertEqual(message, "Email already taken")
            XCTAssertEqual(error.errorDescription, "Email already taken")
        } else {
            XCTFail("Expected apiError, got \(error)")
        }
    }

    func test_fromResponse_extractsJSONErrorKey() {
        let json = "{\"error\":\"Invalid credentials\"}".data(using: .utf8)!
        let response = Response(statusCode: 401, data: json)
        let error = NetworkError.fromResponse(response)

        if case .apiError(let code, let message, _) = error {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(message, "Invalid credentials")
        } else {
            XCTFail("Expected apiError, got \(error)")
        }
    }

    func test_fromResponse_plainText() {
        let text = "Service Temporarily Down".data(using: .utf8)!
        let response = Response(statusCode: 503, data: text)
        let error = NetworkError.fromResponse(response)

        if case .apiError(let code, let message, _) = error {
            XCTAssertEqual(code, 503)
            XCTAssertEqual(message, "Service Temporarily Down")
        } else {
            XCTFail("Expected apiError, got \(error)")
        }
    }

    func test_parseErrorBody_customStruct() {
        let json = "{\"code\":\"AUTH_001\",\"message\":\"Session expired\"}".data(using: .utf8)!
        let error = NetworkError.apiError(statusCode: 401, message: "Session expired", data: json)

        let parsed = error.parseErrorBody(type: SampleBackendError.self)
        XCTAssertEqual(parsed, SampleBackendError(code: "AUTH_001", message: "Session expired"))
    }

    // MARK: - MoyaError Mapping

    func test_fromMoyaError_statusCode401_withoutData_mapsToUnauthorized() {
        let response = Response(statusCode: 401, data: Data())
        let moyaError = MoyaError.statusCode(response)
        XCTAssertEqual(NetworkError.from(moyaError: moyaError), .unauthorized)
    }

    func test_fromMoyaError_timeoutError_mapsToTimeout() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        let moyaError = MoyaError.underlying(urlError, nil)
        XCTAssertEqual(NetworkError.from(moyaError: moyaError), .timeout)
    }

    func test_fromMoyaError_noInternet_mapsToNoInternet() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let moyaError = MoyaError.underlying(urlError, nil)
        XCTAssertEqual(NetworkError.from(moyaError: moyaError), .noInternet)
    }

    // MARK: - Retryable

    func test_isRetryable_serverError() {
        XCTAssertTrue(NetworkError.serverError("test").isRetryable)
    }

    func test_isRetryable_timeout() {
        XCTAssertTrue(NetworkError.timeout.isRetryable)
    }

    func test_isRetryable_noInternet() {
        XCTAssertTrue(NetworkError.noInternet.isRetryable)
    }

    func test_isRetryable_apiError_500() {
        let error = NetworkError.apiError(statusCode: 500, message: "Server error", data: nil)
        XCTAssertTrue(error.isRetryable)
    }

    func test_isNotRetryable_apiError_400() {
        let error = NetworkError.apiError(statusCode: 400, message: "Bad request", data: nil)
        XCTAssertFalse(error.isRetryable)
    }

    func test_isNotRetryable_unauthorized() {
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
    }

    func test_isNotRetryable_decodingError() {
        XCTAssertFalse(NetworkError.decodingError("test").isRetryable)
    }

    // MARK: - Status Code Property

    func test_statusCode_unauthorized() {
        XCTAssertEqual(NetworkError.unauthorized.statusCode, 401)
    }

    func test_statusCode_invalidResponse() {
        XCTAssertEqual(NetworkError.invalidResponse(statusCode: 503).statusCode, 503)
    }

    func test_statusCode_apiError() {
        let error = NetworkError.apiError(statusCode: 422, message: "Validation error", data: nil)
        XCTAssertEqual(error.statusCode, 422)
    }

    func test_statusCode_decodingError_isNil() {
        XCTAssertNil(NetworkError.decodingError("test").statusCode)
    }
}
