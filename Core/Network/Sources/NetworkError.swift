import Foundation
import CoreLocalization

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(String)
    case serverError(String)
    case noData
    case unknown(String)

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
        }
    }
}
