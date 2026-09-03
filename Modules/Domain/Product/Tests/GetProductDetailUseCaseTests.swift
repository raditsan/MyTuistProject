import XCTest
import FactoryKit
@testable import DomainProduct

final class GetProductDetailUseCaseTests: XCTestCase {
    private var mockRepository: MockProductRepository!
    private var sut: GetProductDetailUseCase!

    override func setUp() {
        super.setUp()
        Container.shared.reset()
        mockRepository = MockProductRepository()
        let repo = mockRepository!
        Container.shared.productRepository.register { repo }
        sut = GetProductDetailUseCase()
    }

    override func tearDown() {
        Container.shared.reset()
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    func test_execute_whenSuccess_returnsProduct() async throws {
        // Given
        let expectedProduct = Product(
            id: 42,
            title: "Smart Watch",
            price: 199.99,
            description: "Fitness tracker watch",
            category: "electronics",
            image: "https://example.com/watch.png",
            rating: ProductRating(rate: 4.7, count: 85)
        )
        mockRepository.productDetailToReturn = expectedProduct

        // When
        let result = try await sut.execute(id: 42)

        // Then
        XCTAssertEqual(result.id, 42)
        XCTAssertEqual(result.title, "Smart Watch")
        XCTAssertEqual(result.price, 199.99)
    }

    func test_execute_whenNotFound_throwsError() async {
        // Given
        mockRepository.errorToThrow = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Product not found"])

        // When / Then
        do {
            _ = try await sut.execute(id: 999)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).localizedDescription, "Product not found")
        }
    }
}
