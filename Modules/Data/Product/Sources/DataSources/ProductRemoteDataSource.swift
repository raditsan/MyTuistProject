import Foundation
import CoreNetwork

public enum ProductEndpoint: APIEndpoint {
    case getProducts
    case getProductDetail(id: Int)
    case getCategories

    public var baseURL: String {
        "https://fakestoreapi.com"
    }

    public var path: String {
        switch self {
        case .getProducts:
            return "/products"
        case .getProductDetail(let id):
            return "/products/\(id)"
        case .getCategories:
            return "/products/categories"
        }
    }

    public var method: HTTPMethod {
        .get
    }
}

public protocol ProductRemoteDataSourceProtocol: Sendable {
    func fetchProducts() async throws -> [ProductDTO]
    func fetchProductDetail(id: Int) async throws -> ProductDTO
    func fetchCategories() async throws -> [String]
}

public final class ProductRemoteDataSource: ProductRemoteDataSourceProtocol {
    private let client: any NetworkClientProtocol

    public init(client: any NetworkClientProtocol) {
        self.client = client
    }

    public func fetchProducts() async throws -> [ProductDTO] {
        try await client.request(endpoint: ProductEndpoint.getProducts, type: [ProductDTO].self)
    }

    public func fetchProductDetail(id: Int) async throws -> ProductDTO {
        try await client.request(endpoint: ProductEndpoint.getProductDetail(id: id), type: ProductDTO.self)
    }

    public func fetchCategories() async throws -> [String] {
        try await client.request(endpoint: ProductEndpoint.getCategories, type: [String].self)
    }
}
