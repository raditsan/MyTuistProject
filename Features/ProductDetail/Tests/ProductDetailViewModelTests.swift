import XCTest
import DomainProduct
@testable import FeatureProductDetail

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    private var mockUseCase: MockGetProductDetailUseCase!
    private var sut: ProductDetailViewModel!

    override func setUp() {
        super.setUp()
        mockUseCase = MockGetProductDetailUseCase()
        sut = ProductDetailViewModel(productId: 10, getProductDetailUseCase: mockUseCase)
    }

    override func tearDown() {
        mockUseCase = nil
        sut = nil
        super.tearDown()
    }

    func test_initialState_isIdle() {
        XCTAssertEqual(sut.state, .idle)
    }

    func test_loadDetail_whenSuccess_setsStateToSuccess() async {
        // Given
        let expectedProduct = Product(
            id: 10,
            title: "SanDisk SSD PLUS 1TB",
            price: 109.0,
            description: "Easy upgrade for faster boot up",
            category: "electronics",
            image: "https://example.com/ssd.png",
            rating: ProductRating(rate: 2.9, count: 470)
        )
        mockUseCase.productToReturn = expectedProduct

        // When
        await sut.loadDetail()

        // Then
        XCTAssertEqual(mockUseCase.capturedId, 10)
        if case .success(let product) = sut.state {
            XCTAssertEqual(product.id, 10)
            XCTAssertEqual(product.title, "SanDisk SSD PLUS 1TB")
        } else {
            XCTFail("Expected state to be .success, got \(sut.state)")
        }
    }

    func test_loadDetail_whenFails_setsStateToFailure() async {
        // Given
        mockUseCase.errorToThrow = NSError(
            domain: "NetworkError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Server timeout"]
        )

        // When
        await sut.loadDetail()

        // Then
        if case .failure(let message) = sut.state {
            XCTAssertTrue(message.contains("Server timeout"))
        } else {
            XCTFail("Expected state to be .failure, got \(sut.state)")
        }
    }
}
