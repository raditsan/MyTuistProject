import Foundation
import DomainProduct

public final class MockGetProductsUseCase: GetProductsUseCaseProtocol, @unchecked Sendable {
    public var productsToReturn: [Product] = []
    public var errorToThrow: Error?
    public var lastCategory: String?
    public var lastSearchQuery: String?

    public init() {}

    public func execute(category: String?, searchQuery: String?) async throws -> [Product] {
        lastCategory = category
        lastSearchQuery = searchQuery
        if let error = errorToThrow {
            throw error
        }
        return productsToReturn
    }
}
