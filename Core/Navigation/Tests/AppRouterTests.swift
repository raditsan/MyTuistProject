import XCTest
import SwiftUI
@testable import CoreNavigation

private struct DummyScreen: View {
    var body: some View {
        Text("Dummy Screen")
    }
}

private enum DummyRoute: AppRouteType {
    case first
    case second

    var destination: AppRouteDestination {
        switch self {
        case .first: return .productList
        case .second: return .productDetail
        }
    }

    @MainActor @ViewBuilder
    func makeView() -> some View {
        DummyScreen()
    }
}

@MainActor
final class AppRouterTests: XCTestCase {
    private var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter(navigationController: UINavigationController())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_setRootView_setsNavigationStack() {
        // When
        sut.setRootView(to: DummyRoute.first)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
        let rootVC = sut.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .productList)
    }

    func test_navigate_pushesViewController() {
        // Given
        sut.setRootView(to: DummyRoute.first)

        // When
        sut.navigate(to: DummyRoute.second, animated: false)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .productDetail)
    }

    func test_pop_removesTopViewController() {
        // Given
        sut.setRootView(to: DummyRoute.first)
        sut.navigate(to: DummyRoute.second, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)

        // When
        sut.pop(animated: false)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
    }

    func test_showToast_updatesCurrentToast() {
        // Given
        let toast = ToastMessage(title: "Berhasil", message: "Item ditambahkan", style: .success)

        // When
        sut.showToast(toast)

        // Then
        XCTAssertEqual(sut.alertCoordinator.currentToast?.title, "Berhasil")
        XCTAssertEqual(sut.alertCoordinator.currentToast?.style, .success)
    }

    func test_deepLinkResolve_resolvesProductListAndDetail() {
        // ProductRoute
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product"]), .product(.list))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["products"]), .product(.list))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "42"]), .product(.detailById(42)))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "preload", "42"]), .deeplinkFetch(.product(id: 42)))

        // FavoritesRoute
        XCTAssertEqual(FavoritesRoute.deepLinkResolve(pathComponents: ["favorites"]), .favorites(.list))
        XCTAssertEqual(FavoritesRoute.deepLinkResolve(pathComponents: ["favorite"]), .favorites(.list))

        // ProductRoute
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product-preload", "42"]), .deeplinkFetch(.product(id: 42)))

        // AppRoute
        XCTAssertEqual(AppRoute.deepLinkResolve(pathComponents: ["splash"]), .splash)
        XCTAssertNil(AppRoute.deepLinkResolve(pathComponents: ["unknown"]))
    }

    func test_deepLinkHandler_parse_resolvesRoutesDirectly() {
        let handler = DeepLinkHandler()

        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product")!), .product(.list))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/42")!), .product(.detailById(42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product-preload/42")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/preload/42")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://favorites")!), .favorites(.list))
        XCTAssertNil(handler.parse(url: URL(string: "mytuist://unknown")!))
    }

    func test_deepLinkHandler_parse_withQueryParameters() {
        let handler = DeepLinkHandler()

        // 1. Direct query param: ?id=42
        XCTAssertEqual(
            handler.parse(url: URL(string: "mytuist://product?id=42")!),
            .product(.detailById(42))
        )

        // 2. Query param with path: /detail?id=42
        XCTAssertEqual(
            handler.parse(url: URL(string: "mytuist://product/detail?id=42")!),
            .product(.detailById(42))
        )

        // 3. Query param with preload flag: ?id=42&preload=true
        XCTAssertEqual(
            handler.parse(url: URL(string: "mytuist://product?id=42&preload=true")!),
            .deeplinkFetch(.product(id: 42))
        )

        // 4. Query param with preload shorthand: ?preload=42
        XCTAssertEqual(
            handler.parse(url: URL(string: "mytuist://product?preload=42")!),
            .deeplinkFetch(.product(id: 42))
        )

        // 5. Path preload with query id: /preload?id=42
        XCTAssertEqual(
            handler.parse(url: URL(string: "mytuist://product/preload?id=42")!),
            .deeplinkFetch(.product(id: 42))
        )
    }

    func test_handleURL_navigatesToResolvedRoute() {
        // Given
        AppRouter.viewBuilder = { route in
            AnyView(Text("Mock View for \(String(describing: route))"))
        }
        sut.setRootView(to: .splash)

        // When
        let url = URL(string: "mytuist://product/99")!
        sut.handle(url: url)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .product(.detail))
    }
}
