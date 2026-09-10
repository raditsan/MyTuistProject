import Foundation
import CoreNetwork
import FactoryKit
import Moya

public enum ProductEndpoint: TargetType {
    case getProducts
    case getProductDetail(id: Int)
    case getCategories

    public var baseURL: URL {
        URL(string: AppEnvironment.baseURL) ?? URL(string: "https://fakestoreapi.com")!
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

    public var method: Moya.Method {
        .get
    }

    public var task: Task {
        .requestPlain
    }

    public var headers: [String: String]? {
        ["Content-Type": "application/json", "Accept": "application/json"]
    }
}

public protocol ProductRemoteDataSourceProtocol: Sendable {
    func fetchProducts() async throws -> [ProductDTO]
    func fetchProductDetail(id: Int) async throws -> ProductDTO
    func fetchCategories() async throws -> [String]
}

public final class ProductRemoteDataSource: ProductRemoteDataSourceProtocol, @unchecked Sendable {
    @Injected(\.networkClient) private var client

    public init() {}

    public init(client: any NetworkClientProtocol) {
        self.client = client
    }

    public func fetchProducts() async throws -> [ProductDTO] {
        try await client.request(target: ProductEndpoint.getProducts, type: [ProductDTO].self)
    }

    public func fetchProductDetail(id: Int) async throws -> ProductDTO {
        try await client.request(target: ProductEndpoint.getProductDetail(id: id), type: ProductDTO.self)
    }

    public func fetchCategories() async throws -> [String] {
        try await client.request(target: ProductEndpoint.getCategories, type: [String].self)
    }
}
