import Foundation
import FactoryKit

extension Container {
    public var productRepository: Factory<ProductRepositoryProtocol> {
        self { fatalError("ProductRepositoryProtocol must be registered by Data layer") }
    }

    public var getProductsUseCase: Factory<GetProductsUseCaseProtocol> {
        self { GetProductsUseCase() }
    }

    public var getProductDetailUseCase: Factory<GetProductDetailUseCaseProtocol> {
        self { GetProductDetailUseCase() }
    }
}
