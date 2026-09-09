import Foundation
import Combine
import Moya
import CombineMoya

// MARK: - NetworkClientProtocol

public protocol NetworkClientProtocol: Sendable {
    /// Performs a network request and returns a Combine publisher.
    func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) -> AnyPublisher<T, NetworkError>

    /// Performs a network request using async/await (bridges from Combine).
    func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) async throws -> T

    /// Performs a network request that doesn't expect a response body (e.g., 204 No Content, DELETE, logout).
    func request<Target: TargetType>(
        target: Target
    ) -> AnyPublisher<Void, NetworkError>

    /// Performs a network request using async/await without expecting a response body.
    func request<Target: TargetType>(
        target: Target
    ) async throws
}

public extension NetworkClientProtocol {
    func request<Target: TargetType>(
        target: Target
    ) -> AnyPublisher<Void, NetworkError> {
        request(target: target, type: EmptyResponse.self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func request<Target: TargetType>(
        target: Target
    ) async throws {
        _ = try await request(target: target, type: EmptyResponse.self)
    }
}

// MARK: - MoyaNetworkClient

/// A production-ready network client built on top of Moya + Combine.
///
/// Features:
/// - **Plugin Pipeline**: Native Moya `PluginType` plugins applied to every request/response.
/// - **Shared Session**: Reuses a single `Session` for HTTP Keep-Alive & TCP connection pooling.
/// - **Smart Retry**: Retries only recoverable errors (50x, timeout, network lost) with configurable delay.
/// - **Task Cancellation**: Cooperatively cancels underlying requests when Swift concurrency Tasks are cancelled.
/// - **Empty Body Support**: Full support for 204 No Content and endpoints returning empty responses.
public final class MoyaNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let decoder: JSONDecoder
    private let configuration: NetworkConfiguration
    private let plugins: [PluginType]
    private let session: Session
    private let customProvider: Any?

    // MARK: - Initializers

    /// Creates a new `MoyaNetworkClient` with plugins and configuration.
    /// - Parameters:
    ///   - plugins: Moya `PluginType` plugins applied to requests/responses.
    ///   - configuration: Network configuration (timeout, retry, log level).
    ///   - session: Optional custom Alamofire `Session` (e.g. for SSL pinning). Uses shared session by default.
    ///   - decoder: JSON decoder for response parsing.
    public init(
        plugins: [PluginType] = [],
        configuration: NetworkConfiguration = .default,
        session: Session? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.plugins = plugins
        self.configuration = configuration
        self.decoder = decoder
        self.customProvider = nil

        if let session = session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
            sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval
            self.session = Session(configuration: sessionConfig)
        }
    }

    /// Creates a `MoyaNetworkClient` with a custom `MoyaProvider` for testing.
    /// - Parameters:
    ///   - customProvider: A pre-configured `MoyaProvider` (typically with stubbed responses).
    ///   - plugins: Plugins to apply even in test mode.
    ///   - configuration: Network configuration.
    ///   - session: Custom session.
    ///   - decoder: JSON decoder.
    public init<Target: TargetType>(
        customProvider: MoyaProvider<Target>,
        plugins: [PluginType] = [],
        configuration: NetworkConfiguration = .default,
        session: Session? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.customProvider = customProvider
        self.plugins = plugins
        self.configuration = configuration
        self.decoder = decoder
        self.session = session ?? Session.default
    }

    // MARK: - Combine Publisher (Decodable)

    public func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        let provider = makeProvider(for: target)
        let retryPolicy = configuration.retryPolicy
        let decoder = self.decoder

        return Deferred {
            provider.requestPublisher(target)
                .eraseToAnyPublisher()
        }
        // Validate status codes
        .tryMap { response -> Response in
            guard (200...299).contains(response.statusCode) else {
                throw MoyaError.statusCode(response)
            }
            return response
        }
        .mapError { error -> NetworkError in
            if let moyaError = error as? MoyaError {
                return NetworkError.from(moyaError: moyaError)
            }
            return NetworkError.unknown(error.localizedDescription)
        }
        // Smart retry: only retry retryable network errors (e.g. 50x, timeout, network lost)
        // 404, 401, and client errors fail immediately without wasteful retries.
        .smartRetry(
            retryPolicy.maxRetryCount,
            delay: retryPolicy.retryDelay,
            when: { $0.isRetryable }
        )
        // Decoding is performed AFTER network retry so corrupted JSON does not trigger network retries.
        .flatMap { response -> AnyPublisher<T, NetworkError> in
            if type == EmptyResponse.self, let empty = EmptyResponse() as? T {
                return Just(empty).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            return Just(response.data)
                .decode(type: T.self, decoder: decoder)
                .mapError { error -> NetworkError in
                    NetworkError.decodingError(error.localizedDescription)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Combine Publisher (Void / 204 No Content)

    public func request<Target: TargetType>(
        target: Target
    ) -> AnyPublisher<Void, NetworkError> {
        let provider = makeProvider(for: target)
        let retryPolicy = configuration.retryPolicy

        return Deferred {
            provider.requestPublisher(target)
                .eraseToAnyPublisher()
        }
        .tryMap { response -> Response in
            guard (200...299).contains(response.statusCode) else {
                throw MoyaError.statusCode(response)
            }
            return response
        }
        .mapError { error -> NetworkError in
            if let moyaError = error as? MoyaError {
                return NetworkError.from(moyaError: moyaError)
            }
            return NetworkError.unknown(error.localizedDescription)
        }
        .smartRetry(
            retryPolicy.maxRetryCount,
            delay: retryPolicy.retryDelay,
            when: { $0.isRetryable }
        )
        .map { _ in () }
        .eraseToAnyPublisher()
    }

    // MARK: - Async/Await Bridge (Decodable)

    public func request<T: Decodable, Target: TargetType>(
        target: Target,
        type: T.Type
    ) async throws -> T {
        let box = CancellableBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                box.cancellable = self.request(target: target, type: type)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                            box.cancellable = nil
                        },
                        receiveValue: { value in
                            continuation.resume(returning: value)
                        }
                    )
            }
        } onCancel: {
            box.cancellable?.cancel()
        }
    }

    // MARK: - Async/Await Bridge (Void)

    public func request<Target: TargetType>(
        target: Target
    ) async throws {
        let box = CancellableBox()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                box.cancellable = self.request(target: target)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            box.cancellable = nil
                        },
                        receiveValue: { _ in }
                    )
            }
        } onCancel: {
            box.cancellable?.cancel()
        }
    }

    // MARK: - Provider Factory

    /// Creates a `MoyaProvider` for the given target, reusing the shared `Session`.
    private func makeProvider<Target: TargetType>(for target: Target) -> MoyaProvider<Target> {
        // Use custom provider if available (testing)
        if let custom = customProvider as? MoyaProvider<Target> {
            return custom
        }

        let timeout = self.configuration.timeoutInterval
        let requestClosure: MoyaProvider<Target>.RequestClosure = { endpoint, done in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = timeout
                done(.success(request))
            } catch {
                done(.failure(MoyaError.underlying(error, nil)))
            }
        }

        return MoyaProvider<Target>(
            requestClosure: requestClosure,
            session: session,
            plugins: plugins
        )
    }
}

// MARK: - Helpers

private final class CancellableBox: @unchecked Sendable {
    var cancellable: AnyCancellable?
    init() {}
}

