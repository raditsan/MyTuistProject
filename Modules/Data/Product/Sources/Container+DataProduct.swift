import Foundation
import FactoryKit
import DomainProduct

extension Container {
    public var productRemoteDataSource: Factory<ProductRemoteDataSourceProtocol> {
        self { ProductRemoteDataSource() }.singleton
    }

    public func registerProductDataDependencies() {
        productRepository.register {
            ProductRepository()
        }
    }
}
