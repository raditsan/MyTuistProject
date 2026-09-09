import Foundation
import Moya

// MARK: - Retry Plugin

/// A Moya `PluginType` that inspects responses and converts retryable HTTP status codes
/// (such as 500, 502, 503, 504) into errors so that the Combine pipeline can retry.
///
/// The actual retry execution (with retry count and backoff) is handled by Combine's `.retry()`
/// in `MoyaNetworkClient`.
public final class RetryPlugin: PluginType, @unchecked Sendable {
    private let retryPolicy: RetryPolicy

    /// - Parameter retryPolicy: The retry configuration. Uses `RetryPolicy.default` if not specified.
    public init(retryPolicy: RetryPolicy = .default) {
        self.retryPolicy = retryPolicy
    }

    /// The retry policy used by this plugin.
    public var policy: RetryPolicy { retryPolicy }

    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        switch result {
        case .success(let response):
            if retryPolicy.retryableStatusCodes.contains(response.statusCode) {
                // Convert retryable status codes into failures so the Combine pipeline retries
                return .failure(MoyaError.statusCode(response))
            }
            return result

        case .failure:
            // Network-level errors (timeout, no internet) are already failures and will be retried
            return result
        }
    }
}
