import Foundation
import DomainProduct

public final class MockProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    public var productsToReturn: [Product] = []
    public var productDetailToReturn: Product?
    public var categoriesToReturn: [String] = []
    public var errorToThrow: Error?

    public init() {}

    public func getProducts() async throws -> [Product] {
        if let error = errorToThrow {
            throw error
        }
        return productsToReturn
    }

    public func getProductDetail(id: Int) async throws -> Product {
        if let error = errorToThrow {
            throw error
        }
        if let product = productDetailToReturn {
            return product
        }
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
    }

    public func getCategories() async throws -> [String] {
        if let error = errorToThrow {
            throw error
        }
        return categoriesToReturn
    }
}
