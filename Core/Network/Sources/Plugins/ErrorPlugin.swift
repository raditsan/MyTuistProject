import Foundation
import Moya

// MARK: - Error Handler Protocol

/// Protocol for handling specific network errors globally.
/// Implement this to react to certain HTTP status codes (e.g., force logout on 401).
public protocol NetworkErrorHandler: Sendable {
    /// Called when a specific error condition is detected.
    /// - Parameters:
    ///   - error: The mapped `NetworkError`.
    ///   - target: The endpoint that triggered the error.
    func handleError(_ error: NetworkError, for target: any TargetType)
}

// MARK: - Error Plugin

/// A Moya `PluginType` that performs granular error mapping and invokes a global error handler
/// for specific status codes (e.g., 401 unauthorized).
public final class ErrorPlugin: PluginType, @unchecked Sendable {
    private let errorHandler: NetworkErrorHandler?

    /// - Parameter errorHandler: Optional handler for global error side-effects. Pass `nil` for mapping-only.
    public init(errorHandler: NetworkErrorHandler? = nil) {
        self.errorHandler = errorHandler
    }

    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard case .failure(let moyaError) = result else {
            return
        }

        let networkError = NetworkError.from(moyaError: moyaError)
        errorHandler?.handleError(networkError, for: target)
    }
}

// MARK: - Console Error Handler

/// A simple error handler that prints errors to the console.
/// Useful for development/debugging.
public final class ConsoleErrorHandler: NetworkErrorHandler, @unchecked Sendable {
    public init() {}

    public func handleError(_ error: NetworkError, for target: any TargetType) {
        print("🚨 [NetworkError] \(error.errorDescription ?? "Unknown") — Endpoint: \(type(of: target)).\(target.path)")
    }
}
