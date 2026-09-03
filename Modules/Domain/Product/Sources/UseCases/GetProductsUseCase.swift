import Foundation
import FactoryKit

public protocol GetProductsUseCaseProtocol: Sendable {
    func execute(category: String?, searchQuery: String?) async throws -> [Product]
}

public final class GetProductsUseCase: GetProductsUseCaseProtocol, @unchecked Sendable {
    @Injected(\.productRepository) private var repository: ProductRepositoryProtocol

    public init() {}

    public init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(category: String? = nil, searchQuery: String? = nil) async throws -> [Product] {
        var products = try await repository.getProducts()

        if let category = category, !category.isEmpty, category.lowercased() != "all" {
            products = products.filter { $0.category.lowercased() == category.lowercased() }
        }

        if let searchQuery = searchQuery, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            products = products.filter {
                $0.title.lowercased().contains(query) || $0.description.lowercased().contains(query)
            }
        }

        return products
    }
}
