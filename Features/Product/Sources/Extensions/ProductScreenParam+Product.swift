import Foundation
import CoreNavigation
import DomainProduct

extension ProductScreenParam {
    public init(product: Product) {
        self.init(
            id: product.id,
            title: product.title,
            price: product.price,
            description: product.description,
            category: product.category,
            image: product.image,
            ratingRate: product.rating.rate,
            ratingCount: product.rating.count
        )
    }
}
