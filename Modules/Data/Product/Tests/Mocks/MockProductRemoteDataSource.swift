import Foundation
@testable import DataProduct

public final class MockProductRemoteDataSource: ProductRemoteDataSourceProtocol, @unchecked Sendable {
    public var dtosToReturn: [ProductDTO] = []
    public var detailToReturn: ProductDTO?
    public var categoriesToReturn: [String] = []
    public var errorToThrow: Error?

    public init() {}

    public func fetchProducts() async throws -> [ProductDTO] {
        if let error = errorToThrow {
            throw error
        }
        return dtosToReturn
    }

    public func fetchProductDetail(id: Int) async throws -> ProductDTO {
        if let error = errorToThrow {
            throw error
        }
        if let detail = detailToReturn {
            return detail
        }
        throw NSError(domain: "MockError", code: 404, userInfo: nil)
    }

    public func fetchCategories() async throws -> [String] {
        if let error = errorToThrow {
            throw error
        }
        return categoriesToReturn
    }
}
