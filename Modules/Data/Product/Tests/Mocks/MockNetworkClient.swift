import Foundation
import CoreNetwork

public final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    public var resultToReturn: Any?
    public var errorToThrow: Error?
    public var capturedEndpoint: (any APIEndpoint)?

    public init() {}

    public func request<T: Decodable>(endpoint: any APIEndpoint, type: T.Type) async throws -> T {
        capturedEndpoint = endpoint
        if let error = errorToThrow {
            throw error
        }
        if let result = resultToReturn as? T {
            return result
        }
        throw NetworkError.noData
    }
}
