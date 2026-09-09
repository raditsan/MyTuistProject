import Foundation

/// Represents an empty response body (such as HTTP 204 No Content, or endpoints returning empty payloads).
public struct EmptyResponse: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {
        // Accepts empty data, empty JSON objects, null, or any payload without throwing
    }
}
