import XCTest
@testable import CoreNetwork

private struct DummyEndpoint: APIEndpoint {
    var baseURL: String { "https://api.example.com" }
    var path: String { "/items" }
    var method: HTTPMethod { .post }
    var headers: [String: String]? { ["Authorization": "Bearer token123"] }
    var queryItems: [URLQueryItem]? { [URLQueryItem(name: "page", value: "1")] }
}

final class APIEndpointTests: XCTestCase {
    func test_urlRequest_constructsValidURLRequest() {
        // Given
        let endpoint = DummyEndpoint()

        // When
        let request = endpoint.urlRequest

        // Then
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/items?page=1")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer token123")
    }
}
