import XCTest
import DomainProduct
@testable import DataProduct

final class ProductDTOTests: XCTestCase {
    func test_toDomain_withRating_mapsCorrectly() {
        // Given
        let dto = ProductDTO(
            id: 1,
            title: "Test Item",
            price: 25.5,
            description: "Some description",
            category: "clothing",
            image: "https://example.com/item.png",
            rating: RatingDTO(rate: 4.2, count: 100)
        )

        // When
        let entity = dto.toDomain()

        // Then
        XCTAssertEqual(entity.id, 1)
        XCTAssertEqual(entity.title, "Test Item")
        XCTAssertEqual(entity.price, 25.5)
        XCTAssertEqual(entity.description, "Some description")
        XCTAssertEqual(entity.category, "clothing")
        XCTAssertEqual(entity.image, "https://example.com/item.png")
        XCTAssertEqual(entity.rating.rate, 4.2)
        XCTAssertEqual(entity.rating.count, 100)
    }

    func test_toDomain_withNilRating_providesZeroDefaults() {
        // Given
        let dto = ProductDTO(
            id: 2,
            title: "No Rating Item",
            price: 10.0,
            description: "No rating desc",
            category: "books",
            image: "https://example.com/book.png",
            rating: nil
        )

        // When
        let entity = dto.toDomain()

        // Then
        XCTAssertEqual(entity.rating.rate, 0.0)
        XCTAssertEqual(entity.rating.count, 0)
    }
}
