import Foundation

// MARK: - Log Level

/// Controls the verbosity of network logging.
public enum LogLevel: Int, Sendable, Comparable {
    /// No logging.
    case none = 0
    /// Log only method, URL, and status code.
    case minimal = 1
    /// Log headers + minimal info.
    case standard = 2
    /// Log everything including request/response bodies (truncated).
    case verbose = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Retry Policy

/// Configuration for automatic retry behavior on transient errors.
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts.
    public let maxRetryCount: Int
    /// Base delay between retries (in seconds). Doubled on each subsequent retry (exponential backoff).
    public let retryDelay: TimeInterval
    /// HTTP status codes that should trigger a retry.
    public let retryableStatusCodes: Set<Int>

    public init(
        maxRetryCount: Int = 2,
        retryDelay: TimeInterval = 1.0,
        retryableStatusCodes: Set<Int> = [500, 502, 503, 504]
    ) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
        self.retryableStatusCodes = retryableStatusCodes
    }

    /// No retries.
    public static let none = RetryPolicy(maxRetryCount: 0)

    /// Default retry: 2 attempts, 1s base delay, server errors only.
    public static let `default` = RetryPolicy()
}

// MARK: - Network Configuration

/// Central configuration object for `MoyaNetworkClient`.
/// Controls timeout, retry, and logging behavior.
public struct NetworkConfiguration: Sendable {
    /// Request timeout interval in seconds.
    public let timeoutInterval: TimeInterval
    /// Retry policy for transient failures.
    public let retryPolicy: RetryPolicy
    /// Log verbosity level.
    public let logLevel: LogLevel

    public init(
        timeoutInterval: TimeInterval = 30,
        retryPolicy: RetryPolicy = .default,
        logLevel: LogLevel = .standard
    ) {
        self.timeoutInterval = timeoutInterval
        self.retryPolicy = retryPolicy
        self.logLevel = logLevel
    }

    /// Default configuration: 30s timeout, default retry, standard logging.
    public static let `default` = NetworkConfiguration()

    /// Development configuration: 60s timeout, no retry, verbose logging.
    public static let development = NetworkConfiguration(
        timeoutInterval: 60,
        retryPolicy: .default,
        logLevel: .verbose
    )

    /// Production configuration: 30s timeout, default retry, no logging.
    public static let production = NetworkConfiguration(
        timeoutInterval: 30,
        retryPolicy: .default,
        logLevel: .none
    )
}
