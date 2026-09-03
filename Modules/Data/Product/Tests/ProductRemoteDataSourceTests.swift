import XCTest
import CoreNetwork
@testable import DataProduct

final class ProductRemoteDataSourceTests: XCTestCase {
    private var mockNetworkClient: MockNetworkClient!
    private var sut: ProductRemoteDataSource!

    override func setUp() {
        super.setUp()
        mockNetworkClient = MockNetworkClient()
        sut = ProductRemoteDataSource(client: mockNetworkClient)
    }

    override func tearDown() {
        mockNetworkClient = nil
        sut = nil
        super.tearDown()
    }

    func test_fetchProducts_requestsCorrectEndpoint() async throws {
        // Given
        let expectedDTOs = [
            ProductDTO(
                id: 1,
                title: "Bag",
                price: 50.0,
                description: "Nice bag",
                category: "bags",
                image: "https://example.com/bag.png",
                rating: nil
            )
        ]
        mockNetworkClient.resultToReturn = expectedDTOs

        // When
        let result = try await sut.fetchProducts()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockNetworkClient.capturedEndpoint?.path, "/products")
        XCTAssertEqual(mockNetworkClient.capturedEndpoint?.method, .get)
    }

    func test_fetchProductDetail_requestsCorrectEndpointWithPath() async throws {
        // Given
        let expectedDTO = ProductDTO(
            id: 99,
            title: "Laptop",
            price: 999.0,
            description: "Fast laptop",
            category: "electronics",
            image: "https://example.com/laptop.png",
            rating: RatingDTO(rate: 4.9, count: 20)
        )
        mockNetworkClient.resultToReturn = expectedDTO

        // When
        let result = try await sut.fetchProductDetail(id: 99)

        // Then
        XCTAssertEqual(result.id, 99)
        XCTAssertEqual(mockNetworkClient.capturedEndpoint?.path, "/products/99")
    }

    func test_fetchCategories_requestsCategoriesEndpoint() async throws {
        // Given
        let expectedCategories = ["electronics", "jewelery", "men's clothing"]
        mockNetworkClient.resultToReturn = expectedCategories

        // When
        let result = try await sut.fetchCategories()

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(mockNetworkClient.capturedEndpoint?.path, "/products/categories")
    }
}
