import Foundation

public struct ProductRating: Equatable, Sendable {
    public let rate: Double
    public let count: Int

    public init(rate: Double, count: Int) {
        self.rate = rate
        self.count = count
    }
}

public struct Product: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let price: Double
    public let description: String
    public let category: String
    public let image: String
    public let rating: ProductRating

    public init(
        id: Int,
        title: String,
        price: Double,
        description: String,
        category: String,
        image: String,
        rating: ProductRating
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.description = description
        self.category = category
        self.image = image
        self.rating = rating
    }

    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}
