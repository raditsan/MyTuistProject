import Foundation
import CoreLocalization
import Moya

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(String)
    case serverError(String)
    case noData
    case unknown(String)

    // MARK: - Granular HTTP Error Cases
    case unauthorized        // 401
    case forbidden           // 403
    case notFound            // 404
    case rateLimited         // 429
    case timeout             // Request timeout
    case noInternet          // No network connectivity

    // MARK: - Backend Business / API Error Case
    /// An error returned by the server containing a specific message and response payload.
    case apiError(statusCode: Int, message: String, data: Data?)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.Error.invalidUrl
        case .invalidResponse(let statusCode):
            return L10n.Error.invalidResponse(statusCode)
        case .decodingError(let message):
            return L10n.Error.decoding(message)
        case .serverError(let message):
            return L10n.Error.server(message)
        case .noData:
            return L10n.Error.noData
        case .unknown(let message):
            return L10n.Error.unknown(message)
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .forbidden:
            return "You do not have permission to access this resource."
        case .notFound:
            return "The requested resource was not found."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .timeout:
            return "The request timed out. Please check your connection."
        case .noInternet:
            return "No internet connection. Please check your network settings."
        case .apiError(_, let message, _):
            return message
        }
    }

    /// Whether this error is potentially recoverable by retrying.
    public var isRetryable: Bool {
        switch self {
        case .serverError, .timeout, .noInternet, .rateLimited:
            return true
        case .invalidResponse(let statusCode):
            return [500, 502, 503, 504].contains(statusCode)
        case .apiError(let statusCode, _, _):
            return [500, 502, 503, 504].contains(statusCode)
        default:
            return false
        }
    }

    /// The HTTP status code associated with this error, if applicable.
    public var statusCode: Int? {
        switch self {
        case .invalidResponse(let code): return code
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .rateLimited: return 429
        case .apiError(let code, _, _): return code
        default: return nil
        }
    }

    /// Attempts to decode the raw backend error response data into a custom `Decodable` model.
    public func parseErrorBody<T: Decodable>(type: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard case .apiError(_, _, let data?) = self else { return nil }
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Factory: MoyaError → NetworkError

    public static func from(moyaError: MoyaError) -> NetworkError {
        switch moyaError {
        case .statusCode(let response):
            return fromResponse(response)

        case .underlying(let error, let response):
            if let response = response {
                return fromResponse(response)
            }
            let nsError = error as NSError
            // Detect specific NSURLError codes
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    return .timeout
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost,
                     NSURLErrorDataNotAllowed:
                    return .noInternet
                default:
                    break
                }
            }
            return .serverError(error.localizedDescription)

        case .objectMapping(let error, _), .encodableMapping(let error):
            return .decodingError(error.localizedDescription)

        default:
            return .unknown(moyaError.localizedDescription)
        }
    }

    /// Maps a Moya `Response` to a specific `NetworkError`, extracting server error messages from the body if available.
    public static func fromResponse(_ response: Response) -> NetworkError {
        // Try to parse structured error message from response JSON
        if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
            let candidateKeys = ["message", "error", "detail", "description", "msg"]
            for key in candidateKeys {
                if let message = json[key] as? String, !message.isEmpty {
                    return .apiError(statusCode: response.statusCode, message: message, data: response.data)
                }
            }
        }

        switch response.statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        default:
            if let stringBody = String(data: response.data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !stringBody.isEmpty, stringBody.count < 300, !stringBody.hasPrefix("<") {
                // Plain text error message (non-HTML) for non-standard status codes
                return .apiError(statusCode: response.statusCode, message: stringBody, data: response.data)
            }
            return .invalidResponse(statusCode: response.statusCode)
        }
    }

    /// Maps an HTTP status code to a specific `NetworkError` case.
    public static func fromStatusCode(_ statusCode: Int) -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        default:
            return .invalidResponse(statusCode: statusCode)
        }
    }
}
