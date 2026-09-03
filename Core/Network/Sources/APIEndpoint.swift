import Foundation

public protocol APIEndpoint: Sendable {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension APIEndpoint {
    var headers: [String: String]? {
        ["Content-Type": "application/json", "Accept": "application/json"]
    }
    
    var queryItems: [URLQueryItem]? {
        nil
    }

    var urlRequest: URLRequest? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
