import XCTest
@testable import DomainProduct

final class ProductEntityTests: XCTestCase {
    func test_formattedPrice_formatsAsCurrency() {
        // Given
        let product = Product(
            id: 1,
            title: "Price Test",
            price: 1234.5,
            description: "",
            category: "",
            image: "",
            rating: ProductRating(rate: 0, count: 0)
        )

        // Then
        XCTAssertTrue(product.formattedPrice.contains("1,234.50") || product.formattedPrice.contains("$"))
    }
}
