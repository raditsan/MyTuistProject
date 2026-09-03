import Foundation
import DomainProduct
import FactoryKit

public final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    @Injected(\.productRemoteDataSource) private var remoteDataSource: ProductRemoteDataSourceProtocol

    public init() {}

    public init(remoteDataSource: ProductRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    public func getProducts() async throws -> [Product] {
        let dtos = try await remoteDataSource.fetchProducts()
        return dtos.map { $0.toDomain() }
    }

    public func getProductDetail(id: Int) async throws -> Product {
        let dto = try await remoteDataSource.fetchProductDetail(id: id)
        return dto.toDomain()
    }

    public func getCategories() async throws -> [String] {
        try await remoteDataSource.fetchCategories()
    }
}
