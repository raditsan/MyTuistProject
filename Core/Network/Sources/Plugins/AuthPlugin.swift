import Foundation
import Moya

// MARK: - Token Provider Protocol

/// Protocol for providing authentication tokens.
/// Implement this protocol to supply tokens from Keychain, UserDefaults, or any other source.
public protocol TokenProvider: Sendable {
    /// Returns the current authentication token, or `nil` if not authenticated.
    func currentToken() -> String?
}

// MARK: - Authenticatable Endpoint

/// Protocol for endpoints that optionally require authentication.
/// Conform your `TargetType` enum to this to control auth header injection per-endpoint.
public protocol AuthenticatableEndpoint {
    /// Whether this endpoint requires an Authorization header. Defaults to `true`.
    var requiresAuth: Bool { get }
}

public extension AuthenticatableEndpoint {
    var requiresAuth: Bool { true }
}

// MARK: - Auth Plugin

/// A Moya `PluginType` that injects an `Authorization: Bearer <token>` header into requests
/// that require authentication.
///
/// Uses `TokenProvider` to retrieve the token and `AuthenticatableEndpoint` to
/// determine whether a given endpoint needs auth.
///
/// Usage:
/// ```swift
/// let authPlugin = AuthPlugin(tokenProvider: MyKeychainTokenProvider())
/// ```
public final class AuthPlugin: PluginType, @unchecked Sendable {
    private let tokenProvider: TokenProvider
    private let scheme: String

    /// - Parameters:
    ///   - tokenProvider: The provider that supplies the current auth token.
    ///   - scheme: The authorization scheme. Default: `"Bearer"`.
    public init(tokenProvider: TokenProvider, scheme: String = "Bearer") {
        self.tokenProvider = tokenProvider
        self.scheme = scheme
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        // Check if the endpoint explicitly opts out of authentication
        if let authenticatable = target as? AuthenticatableEndpoint, !authenticatable.requiresAuth {
            return request
        }

        // Inject token if available
        guard let token = tokenProvider.currentToken(), !token.isEmpty else {
            return request
        }

        var mutatedRequest = request
        mutatedRequest.setValue("\(scheme) \(token)", forHTTPHeaderField: "Authorization")
        return mutatedRequest
    }
}

// MARK: - Static Token Provider (for testing/simple use cases)

/// A simple `TokenProvider` that always returns a fixed token.
/// Useful for testing or when the token is known at compile time.
public final class StaticTokenProvider: TokenProvider, @unchecked Sendable {
    private let token: String?

    public init(token: String?) {
        self.token = token
    }

    public func currentToken() -> String? {
        return token
    }
}
