import XCTest
@testable import CoreNetwork

final class EmptyResponseTests: XCTestCase {

    func test_emptyResponse_init_and_equality() {
        let resp1 = EmptyResponse()
        let resp2 = EmptyResponse()
        XCTAssertEqual(resp1, resp2)
    }

    func test_emptyResponse_decode_fromEmptyObject() throws {
        let json = "{}".data(using: .utf8)!
        let response = try JSONDecoder().decode(EmptyResponse.self, from: json)
        XCTAssertEqual(response, EmptyResponse())
    }

    func test_emptyResponse_decode_fromArbitraryPayload() throws {
        let json = "{\"status\":\"ok\",\"code\":200}".data(using: .utf8)!
        let response = try JSONDecoder().decode(EmptyResponse.self, from: json)
        XCTAssertEqual(response, EmptyResponse())
    }

    func test_emptyResponse_decode_fromNull() throws {
        let json = "null".data(using: .utf8)!
        let response = try JSONDecoder().decode(EmptyResponse.self, from: json)
        XCTAssertEqual(response, EmptyResponse())
    }
}
