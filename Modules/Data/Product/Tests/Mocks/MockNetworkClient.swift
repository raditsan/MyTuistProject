import Foundation
import Combine
import CoreNetwork
import Moya

public final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    public var resultToReturn: Any?
    public var errorToThrow: Error?
    public var capturedTarget: (any TargetType)?

    public var capturedEndpoint: (any TargetType)? {
        capturedTarget
    }

    public init() {}

    public func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        capturedTarget = target
        if let error = errorToThrow as? NetworkError {
            return Fail(error: error).eraseToAnyPublisher()
        } else if let error = errorToThrow {
            return Fail(error: NetworkError.serverError(error.localizedDescription)).eraseToAnyPublisher()
        }
        if let result = resultToReturn as? T {
            return Just(result)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }
        return Fail(error: NetworkError.noData).eraseToAnyPublisher()
    }

    public func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) async throws -> T {
        capturedTarget = target
        if let error = errorToThrow {
            throw error
        }
        if let result = resultToReturn as? T {
            return result
        }
        throw NetworkError.noData
    }
}
