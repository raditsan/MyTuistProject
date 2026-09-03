import Foundation
import DomainProduct

public final class MockGetProductDetailUseCase: GetProductDetailUseCaseProtocol, @unchecked Sendable {
    public var productToReturn: Product?
    public var errorToThrow: Error?
    public var capturedId: Int?

    public init() {}

    public func execute(id: Int) async throws -> Product {
        capturedId = id
        if let error = errorToThrow {
            throw error
        }
        if let product = productToReturn {
            return product
        }
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
    }
}
