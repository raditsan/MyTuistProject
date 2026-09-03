import XCTest
import DomainProduct
@testable import FeatureProduct

@MainActor
final class ProductListViewModelTests: XCTestCase {
    private var mockUseCase: MockGetProductsUseCase!
    private var mockRepository: MockProductRepository!
    private var sut: ProductListViewModel!

    override func setUp() {
        super.setUp()
        mockUseCase = MockGetProductsUseCase()
        mockRepository = MockProductRepository()
        sut = ProductListViewModel(
            getProductsUseCase: mockUseCase,
            repository: mockRepository
        )
    }

    override func tearDown() {
        mockUseCase = nil
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    private func makeDummyProduct() -> Product {
        Product(
            id: 1,
            title: "Test Product",
            price: 50.0,
            description: "Some description",
            category: "electronics",
            image: "https://example.com/img.png",
            rating: ProductRating(rate: 4.0, count: 10)
        )
    }

    func test_fetchProducts_whenSuccess_setsStateToSuccess() async {
        // Given
        let products = [makeDummyProduct()]
        mockUseCase.productsToReturn = products

        // When
        await sut.fetchProducts()

        // Then
        if case .success(let items) = sut.state {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.id, 1)
        } else {
            XCTFail("Expected state to be .success, got \(sut.state)")
        }
    }

    func test_fetchProducts_whenEmpty_setsStateToEmpty() async {
        // Given
        mockUseCase.productsToReturn = []

        // When
        await sut.fetchProducts()

        // Then
        XCTAssertEqual(sut.state, .empty)
    }

    func test_fetchProducts_whenFails_setsStateToFailure() async {
        // Given
        mockUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to connect"]
        )

        // When
        await sut.fetchProducts()

        // Then
        if case .failure(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to connect"))
        } else {
            XCTFail("Expected state to be .failure, got \(sut.state)")
        }
    }

    func test_loadCategories_populatesCategoriesWithAllPrefix() async {
        // Given
        mockRepository.categoriesToReturn = ["electronics", "jewelery"]

        // When
        await sut.loadCategories()

        // Then
        XCTAssertEqual(sut.categories, ["All", "electronics", "jewelery"])
    }
}
