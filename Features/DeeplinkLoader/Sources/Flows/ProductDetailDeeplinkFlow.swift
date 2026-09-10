import Foundation
import CoreNavigation
import DomainProduct
import CoreLocalization
import FactoryKit

/// Flow untuk fetch Product Detail dari Deeplink dengan preloading API
@MainActor
public final class ProductDetailDeeplinkFlow: DeeplinkFlow {
    private let productId: Int
    @Injected(\.getProductDetailUseCase) private var getProductDetailUseCase
    @Injected(\.router) private var router

    public init(productId: Int) {
        self.productId = productId
    }

    public func execute(update: @escaping DeeplinkFlowUpdate) async {
        update(.setLoading(true, message: L10n.Deeplink.Loading.product(productId)))
        update(.setError(nil))

        do {
            let product = try await getProductDetailUseCase.execute(id: productId)
            update(.setLoading(false, message: nil))
            await router.dismissDeeplinkLoader()
            router.navigate(to: .product(.detail(id: product.id)))
        } catch {
            update(.setLoading(false, message: nil))
            update(.setError(error.localizedDescription))
        }
    }
}
