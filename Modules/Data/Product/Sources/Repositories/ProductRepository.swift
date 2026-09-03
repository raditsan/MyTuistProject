import Foundation
import DomainProduct

public final class ProductRepository: ProductRepositoryProtocol {
    private let remoteDataSource: ProductRemoteDataSourceProtocol

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
