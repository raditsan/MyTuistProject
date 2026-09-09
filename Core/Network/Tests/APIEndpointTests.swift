import XCTest
import Moya
@testable import CoreNetwork

private struct DummyEndpoint: TargetType {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/items" }
    var method: Moya.Method { .post }
    var task: Task { .requestParameters(parameters: ["page": 1], encoding: URLEncoding.queryString) }
    var headers: [String: String]? { ["Authorization": "Bearer token123"] }
    var sampleData: Data { Data() }
}

final class APIEndpointTests: XCTestCase {
    func test_targetType_properties() {
        let endpoint = DummyEndpoint()

        XCTAssertEqual(endpoint.baseURL.absoluteString, "https://api.example.com")
        XCTAssertEqual(endpoint.path, "/items")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.headers?["Authorization"], "Bearer token123")
        XCTAssertEqual(endpoint.sampleData, Data())
    }

    func test_defaultHeaders() {
        let endpoint = DummyEndpoint()
        XCTAssertEqual(endpoint.defaultHeaders["Content-Type"], "application/json")
    }
}
