import Foundation
import DomainProduct

public struct RatingDTO: Codable, Sendable {
    public let rate: Double
    public let count: Int

    public init(rate: Double, count: Int) {
        self.rate = rate
        self.count = count
    }
}

public struct ProductDTO: Codable, Sendable {
    public let id: Int
    public let title: String
    public let price: Double
    public let description: String
    public let category: String
    public let image: String
    public let rating: RatingDTO?

    public init(
        id: Int,
        title: String,
        price: Double,
        description: String,
        category: String,
        image: String,
        rating: RatingDTO?
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.description = description
        self.category = category
        self.image = image
        self.rating = rating
    }

    public func toDomain() -> Product {
        Product(
            id: id,
            title: title,
            price: price,
            description: description,
            category: category,
            image: image,
            rating: ProductRating(
                rate: rating?.rate ?? 0.0,
                count: rating?.count ?? 0
            )
        )
    }
}
