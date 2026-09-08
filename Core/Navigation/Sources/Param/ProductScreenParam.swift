import Foundation

/// Navigation parameter for Product detail screen.
/// Kept in CoreNavigation without any dependency to Domain entities.
public struct ProductScreenParam: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String?
    public let price: Double?
    public let description: String?
    public let category: String?
    public let image: String?
    public let ratingRate: Double?
    public let ratingCount: Int?

    public init(
        id: Int,
        title: String? = nil,
        price: Double? = nil,
        description: String? = nil,
        category: String? = nil,
        image: String? = nil,
        ratingRate: Double? = nil,
        ratingCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.description = description
        self.category = category
        self.image = image
        self.ratingRate = ratingRate
        self.ratingCount = ratingCount
    }
}
