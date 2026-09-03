import Foundation
import DomainProduct

public enum DetailViewState<T: Equatable>: Equatable {
    case idle
    case loading
    case success(T)
    case empty
    case failure(String)
}

@MainActor
public final class ProductDetailViewModel: ObservableObject {
    @Published public private(set) var state: DetailViewState<Product> = .idle

    private let productId: Int
    private let getProductDetailUseCase: GetProductDetailUseCaseProtocol

    public init(
        productId: Int,
        getProductDetailUseCase: GetProductDetailUseCaseProtocol
    ) {
        self.productId = productId
        self.getProductDetailUseCase = getProductDetailUseCase
    }

    public func loadDetail() async {
        state = .loading
        do {
            let product = try await getProductDetailUseCase.execute(id: productId)
            state = .success(product)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}
