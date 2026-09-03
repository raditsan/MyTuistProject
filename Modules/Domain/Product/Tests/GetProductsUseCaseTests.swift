import XCTest
import FactoryKit
@testable import DomainProduct

final class GetProductsUseCaseTests: XCTestCase {
    private var mockRepository: MockProductRepository!
    private var sut: GetProductsUseCase!

    override func setUp() {
        super.setUp()
        Container.shared.reset()
        mockRepository = MockProductRepository()
        let repo = mockRepository!
        Container.shared.productRepository.register { repo }
        sut = GetProductsUseCase()
    }

    override func tearDown() {
        Container.shared.reset()
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    private func createDummyProducts() -> [Product] {
        [
            Product(
                id: 1,
                title: "Fjallraven Backpack",
                price: 109.95,
                description: "Your perfect pack for everyday use.",
                category: "men's clothing",
                image: "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg",
                rating: ProductRating(rate: 3.9, count: 120)
            ),
            Product(
                id: 2,
                title: "Mens Casual Premium Slim Fit T-Shirts",
                price: 22.3,
                description: "Slim-fitting style, contrast raglan long sleeve.",
                category: "men's clothing",
                image: "https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg",
                rating: ProductRating(rate: 4.1, count: 259)
            ),
            Product(
                id: 3,
                title: "John Hardy Women's Legends Naga Gold & Silver Bracelet",
                price: 695.0,
                description: "From our Legends Collection, the Naga was inspired by the mythical water dragon.",
                category: "jewelery",
                image: "https://fakestoreapi.com/img/71pWzhdJNwL._AC_UL640_QL65_ML3_.jpg",
                rating: ProductRating(rate: 4.6, count: 400)
            )
        ]
    }

    func test_execute_withoutFilters_returnsAllProducts() async throws {
        // Given
        let dummy = createDummyProducts()
        mockRepository.productsToReturn = dummy

        // When
        let result = try await sut.execute(category: nil, searchQuery: nil)

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.id, 1)
    }

    func test_execute_filterByCategory_returnsFilteredProducts() async throws {
        // Given
        let dummy = createDummyProducts()
        mockRepository.productsToReturn = dummy

        // When
        let result = try await sut.execute(category: "jewelery", searchQuery: nil)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "John Hardy Women's Legends Naga Gold & Silver Bracelet")
    }

    func test_execute_searchQuery_returnsMatchingProducts() async throws {
        // Given
        let dummy = createDummyProducts()
        mockRepository.productsToReturn = dummy

        // When
        let result = try await sut.execute(category: nil, searchQuery: "backpack")

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, 1)
    }

    func test_execute_whenRepositoryFails_throwsError() async {
        // Given
        let expectedError = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        mockRepository.errorToThrow = expectedError

        // When / Then
        do {
            _ = try await sut.execute(category: nil, searchQuery: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
