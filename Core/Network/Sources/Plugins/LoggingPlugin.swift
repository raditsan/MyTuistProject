import Foundation
import Moya

// MARK: - Logging Plugin

/// A Moya `PluginType` that logs network request and response details to the console.
/// Respects `LogLevel` to control verbosity.
public final class LoggingPlugin: PluginType, @unchecked Sendable {
    private let logLevel: LogLevel
    private let maxBodyLength: Int

    /// - Parameters:
    ///   - logLevel: The verbosity of logging output.
    ///   - maxBodyLength: Maximum number of characters to print for request/response bodies. Default: 500.
    public init(logLevel: LogLevel = .standard, maxBodyLength: Int = 500) {
        self.logLevel = logLevel
        self.maxBodyLength = maxBodyLength
    }

    public func willSend(_ request: RequestType, target: TargetType) {
        guard logLevel >= .minimal else { return }

        let urlRequest = request.request
        let method = urlRequest?.httpMethod ?? "UNKNOWN"
        let url = urlRequest?.url?.absoluteString ?? "N/A"

        print("🌐 [\(method)] \(url)")

        if logLevel >= .standard {
            if let headers = urlRequest?.allHTTPHeaderFields, !headers.isEmpty {
                print("   📋 Headers: \(headers)")
            }
        }

        if logLevel >= .verbose {
            if let body = urlRequest?.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                let truncated = bodyString.prefix(maxBodyLength)
                let suffix = bodyString.count > maxBodyLength ? "... (truncated)" : ""
                print("   📦 Body: \(truncated)\(suffix)")
            }
        }
    }

    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard logLevel >= .minimal else { return }

        switch result {
        case .success(let response):
            let statusEmoji = (200..<300).contains(response.statusCode) ? "✅" : "⚠️"
            print("   \(statusEmoji) Status: \(response.statusCode) (\(response.data.count) bytes)")

            if logLevel >= .verbose {
                if let bodyString = String(data: response.data, encoding: .utf8) {
                    let truncated = bodyString.prefix(maxBodyLength)
                    let suffix = bodyString.count > maxBodyLength ? "... (truncated)" : ""
                    print("   📥 Response: \(truncated)\(suffix)")
                }
            }

        case .failure(let error):
            print("   ❌ Error: \(error.localizedDescription)")
        }
    }
}
