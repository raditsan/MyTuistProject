import Foundation
import Moya
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Header Plugin

/// A Moya `PluginType` that injects global HTTP headers into outgoing network requests.
///
/// Use this to automatically inject app-wide headers such as `X-Platform`, `X-App-Version`,
/// `X-OS-Version`, `Accept-Language`, and custom tracking IDs without cluttering individual `TargetType` enums.
public final class HeaderPlugin: PluginType, @unchecked Sendable {
    public typealias HeaderProvider = @Sendable () -> [String: String]
    private let headerProvider: HeaderProvider

    /// Creates a `HeaderPlugin` with dynamic header provider closure.
    public init(headerProvider: @escaping HeaderProvider) {
        self.headerProvider = headerProvider
    }

    /// Creates a `HeaderPlugin` with fixed static headers.
    public init(headers: [String: String]) {
        self.headerProvider = { headers }
    }

    /// Pre-configured plugin with standard iOS application metadata headers:
    /// - `X-Platform`: `"iOS"`
    /// - `X-App-Version`: CFBundleShortVersionString (e.g. `"1.0.0"`)
    /// - `X-OS-Version`: Current iOS version (e.g. `"17.0"`)
    /// - `X-Bundle-Id`: Bundle identifier
    /// - `Accept-Language`: User's preferred language code
    public static var defaultAppMetadata: HeaderPlugin {
        HeaderPlugin {
            var headers: [String: String] = [:]
            headers["X-Platform"] = "iOS"

            #if canImport(UIKit)
            headers["X-OS-Version"] = UIDevice.current.systemVersion
            #endif

            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                headers["X-App-Version"] = appVersion
            }

            if let bundleId = Bundle.main.bundleIdentifier {
                headers["X-Bundle-Id"] = bundleId
            }

            if let language = Locale.preferredLanguages.first {
                headers["Accept-Language"] = language
            }

            return headers
        }
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var mutatedRequest = request
        let globalHeaders = headerProvider()

        for (key, value) in globalHeaders {
            // Do not overwrite headers explicitly defined on the TargetType
            if mutatedRequest.value(forHTTPHeaderField: key) == nil {
                mutatedRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return mutatedRequest
    }
}
