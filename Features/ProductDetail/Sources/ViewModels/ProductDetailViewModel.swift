import Foundation
import DomainProduct
import FactoryKit

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

    public let productId: Int
    @Injected(\.getProductDetailUseCase) private var getProductDetailUseCase: GetProductDetailUseCaseProtocol

    public init(productId: Int) {
        self.productId = productId
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
