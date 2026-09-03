import Foundation
import FactoryKit

public protocol GetProductDetailUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> Product
}

public final class GetProductDetailUseCase: GetProductDetailUseCaseProtocol, @unchecked Sendable {
    @Injected(\.productRepository) private var repository: ProductRepositoryProtocol

    public init() {}

    public init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> Product {
        try await repository.getProductDetail(id: id)
    }
}
