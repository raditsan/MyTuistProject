import XCTest
import CoreNavigation
import DomainProduct
import FactoryKit
@testable import FeatureDeeplinkLoader

private final class MockGetProductDetailUseCaseSuccess: GetProductDetailUseCaseProtocol, @unchecked Sendable {
    func execute(id: Int) async throws -> Product {
        return Product(
            id: id,
            title: "Preloaded Product",
            price: 99.0,
            description: "Preloaded Description",
            category: "electronics",
            image: "https://example.com/image.png",
            rating: ProductRating(rate: 4.5, count: 10)
        )
    }
}

private final class MockGetProductDetailUseCaseFailure: GetProductDetailUseCaseProtocol, @unchecked Sendable {
    func execute(id: Int) async throws -> Product {
        throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not found"])
    }
}

@MainActor
final class ProductDetailDeeplinkFlowTests: XCTestCase {
    private var router: AppRouter!

    override func setUp() {
        super.setUp()
        router = AppRouter(navigationController: UINavigationController())
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    func test_execute_whenSuccess_navigatesToProductDetail() async {
        Container.shared.getProductDetailUseCase.register { MockGetProductDetailUseCaseSuccess() }
        let sut = ProductDetailDeeplinkFlow(productId: 42)

        var actionsReceived: [DeeplinkFlowUIAction] = []
        await sut.execute(router: router) { action in
            actionsReceived.append(action)
        }

        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
        let topVC = router.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .product(.detail))
    }

    func test_execute_whenFailure_emitsError() async {
        Container.shared.getProductDetailUseCase.register { MockGetProductDetailUseCaseFailure() }
        let sut = ProductDetailDeeplinkFlow(productId: 42)

        var lastError: String?
        await sut.execute(router: router) { action in
            if case let .setError(error) = action {
                lastError = error
            }
        }

        XCTAssertEqual(lastError, "Product not found")
        XCTAssertEqual(router.navigationController.viewControllers.count, 0)
    }
}
