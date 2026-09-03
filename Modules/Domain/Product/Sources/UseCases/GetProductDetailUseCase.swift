import Foundation

public protocol GetProductDetailUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> Product
}

public final class GetProductDetailUseCase: GetProductDetailUseCaseProtocol {
    private let repository: ProductRepositoryProtocol

    public init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> Product {
        try await repository.getProductDetail(id: id)
    }
}
