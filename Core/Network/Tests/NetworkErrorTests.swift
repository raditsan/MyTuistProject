import XCTest
@testable import CoreNetwork

final class NetworkErrorTests: XCTestCase {
    func test_errorDescriptions_areNotEmpty() {
        let errors: [NetworkError] = [
            .invalidURL,
            .invalidResponse(statusCode: 404),
            .decodingError("corrupted JSON"),
            .serverError("500 Internal"),
            .noData,
            .unknown("something broke")
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
}
