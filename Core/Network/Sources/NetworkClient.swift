import Foundation

public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(endpoint: any APIEndpoint, type: T.Type) async throws -> T
}

public final class URLSessionNetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    public func request<T: Decodable>(endpoint: any APIEndpoint, type: T.Type) async throws -> T {
        guard let urlRequest = endpoint.urlRequest else {
            throw NetworkError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw NetworkError.serverError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Respon bukan merupakan HTTPURLResponse")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            throw NetworkError.decodingError("Data corrupted: \(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            throw NetworkError.decodingError("Key '\(key.stringValue)' not found: \(context.debugDescription)")
        } catch let DecodingError.valueNotFound(value, context) {
            throw NetworkError.decodingError("Value '\(value)' not found: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            throw NetworkError.decodingError("Type '\(type)' mismatch: \(context.debugDescription)")
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
}
