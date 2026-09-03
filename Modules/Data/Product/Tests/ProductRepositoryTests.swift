import XCTest
import DomainProduct
@testable import DataProduct

final class ProductRepositoryTests: XCTestCase {
    private var mockRemoteDataSource: MockProductRemoteDataSource!
    private var sut: ProductRepository!

    override func setUp() {
        super.setUp()
        mockRemoteDataSource = MockProductRemoteDataSource()
        sut = ProductRepository(remoteDataSource: mockRemoteDataSource)
    }

    override func tearDown() {
        mockRemoteDataSource = nil
        sut = nil
        super.tearDown()
    }

    func test_getProducts_mapsDTOToDomainEntitiesSuccessfully() async throws {
        // Given
        let dtos = [
            ProductDTO(
                id: 1,
                title: "Test Item",
                price: 19.99,
                description: "Description test",
                category: "electronics",
                image: "https://example.com/image.png",
                rating: RatingDTO(rate: 4.5, count: 50)
            )
        ]
        mockRemoteDataSource.dtosToReturn = dtos

        // When
        let products = try await sut.getProducts()

        // Then
        XCTAssertEqual(products.count, 1)
        let product = products[0]
        XCTAssertEqual(product.id, 1)
        XCTAssertEqual(product.title, "Test Item")
        XCTAssertEqual(product.price, 19.99)
        XCTAssertEqual(product.rating.rate, 4.5)
    }

    func test_getProductDetail_mapsDTOToDomainEntitySuccessfully() async throws {
        // Given
        let dto = ProductDTO(
            id: 10,
            title: "Specific Product",
            price: 99.0,
            description: "Detailed description",
            category: "jewelery",
            image: "https://example.com/detail.png",
            rating: RatingDTO(rate: 4.8, count: 12)
        )
        mockRemoteDataSource.detailToReturn = dto

        // When
        let product = try await sut.getProductDetail(id: 10)

        // Then
        XCTAssertEqual(product.id, 10)
        XCTAssertEqual(product.title, "Specific Product")
        XCTAssertEqual(product.category, "jewelery")
    }

    func test_getProducts_whenDataSourceFails_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "RemoteDataSourceError", code: 400, userInfo: nil)
        mockRemoteDataSource.errorToThrow = expectedError

        // When / Then
        do {
            _ = try await sut.getProducts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
