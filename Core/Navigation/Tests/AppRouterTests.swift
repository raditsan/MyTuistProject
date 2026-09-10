import XCTest
import SwiftUI
import UIKit
import FactoryKit
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
        AppRouter.viewBuilder = { route in
            AnyView(Text("Mock View for \(String(describing: route))"))
        }
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Navigation Mechanics

    func test_init_defaultNavigationController() {
        let defaultRouter = AppRouter()
        XCTAssertNotNil(defaultRouter.navigationController)
    }

    func test_setRootView_setsNavigationStack() {
        sut.setRootView(to: DummyRoute.first)

        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
        let rootVC = sut.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .productList)
    }

    func test_setRootView_withRawView() {
        sut.setRootView(Text("Raw View"))
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
        let rootVC = sut.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertNil(rootVC?.routeDestination)
    }

    func test_setRootView_withAppRoute() {
        sut.setRootView(to: .splash)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
        let rootVC = sut.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .splash)
    }

    func test_navigate_pushesViewController() {
        sut.setRootView(to: DummyRoute.first)
        sut.navigate(to: DummyRoute.second, animated: false)

        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .productDetail)
    }

    func test_navigate_variants() {
        sut.setRootView(to: .splash)

        // 1. router.navigate(_ route: AppRoute)
        sut.navigate(.product(.list), animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)

        // 2. router.navigate(to route: AppRoute)
        sut.navigate(to: .favorites(.list), animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 3)

        // 3. router.navigate(_ route: R)
        sut.navigate(DummyRoute.first, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 4)

        // 4. router.navigate(to route: R)
        sut.navigate(to: DummyRoute.second, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 5)
    }

    func test_pop_removesTopViewController() {
        sut.setRootView(to: DummyRoute.first)
        sut.navigate(to: DummyRoute.second, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)

        sut.pop(animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
    }

    func test_popToRoute() {
        sut.setRootView(to: DummyRoute.first) // .productList
        sut.navigate(to: DummyRoute.second, animated: false) // .productDetail
        sut.navigate(to: DummyRoute.second, animated: false) // .productDetail
        XCTAssertEqual(sut.navigationController.viewControllers.count, 3)

        // Pop to matching destination
        sut.popToRoute(.productList, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)

        // Pop to non-existing destination (no-op)
        sut.popToRoute(.splash, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
    }

@MainActor
private final class MockNavigationController: UINavigationController {
    var presentCallCount = 0
    var dismissCallCount = 0
    private var mockPresentedVC: UIViewController?

    override var presentedViewController: UIViewController? {
        mockPresentedVC
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCallCount += 1
        mockPresentedVC = viewControllerToPresent
        completion?()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCallCount += 1
        mockPresentedVC = nil
        completion?()
    }
}

    // MARK: - Presentation & Modals

    func test_presentSheet_configurations_and_dismiss() async {
        let mockNav = MockNavigationController()
        let router = AppRouter(navigationController: mockNav)

        let sheetConfig = SheetConfiguration.detents(
            [.medium, .large, .fraction(0.4), .height(300)],
            selectedDetent: .medium,
            dragIndicator: .visible,
            cornerRadius: 16,
            largestUndimmedDetent: .medium,
            isTransparent: true
        )

        // Present with View
        router.presentSheet(Text("Custom Sheet"), configuration: sheetConfig, animated: false)
        XCTAssertNotNil(router.navigationController.presentedViewController)
        XCTAssertEqual(mockNav.presentCallCount, 1)

        await router.dismissModalAsync(animated: false)
        XCTAssertNil(router.navigationController.presentedViewController)
        XCTAssertEqual(mockNav.dismissCallCount, 1)

        // Present with AppRoute
        router.presentSheet(to: .splash, configuration: .default, animated: false)
        XCTAssertNotNil(router.navigationController.presentedViewController)

        let exp = expectation(description: "dismiss completion")
        router.dismissModal(animated: false) {
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 2.0)

        // Present with AppRouteType
        router.presentSheet(to: DummyRoute.first, animated: false)
        XCTAssertNotNil(router.navigationController.presentedViewController)
        await router.dismissModalAsync(animated: false)

        // Early return guard when nothing presented
        await router.dismissModalAsync(animated: false)
    }

    func test_deeplinkLoader_and_dismissDeeplinkLoader() async {
        let mockNav = MockNavigationController()
        let router = AppRouter(navigationController: mockNav)

        router.deeplinkLoader(.general)
        XCTAssertNotNil(router.navigationController.presentedViewController)
        XCTAssertEqual(mockNav.presentCallCount, 1)

        await router.dismissDeeplinkLoader()
        XCTAssertNil(router.navigationController.presentedViewController)
        XCTAssertEqual(mockNav.dismissCallCount, 1)

        // Early return guard when nothing presented
        await router.dismissDeeplinkLoader()
    }

    // MARK: - Toasts & AlertCoordinator

    func test_showToast_updatesCurrentToast() {
        let toast = ToastMessage(title: "Berhasil", message: "Item ditambahkan", style: .success)
        sut.showToast(toast)

        XCTAssertEqual(sut.alertCoordinator.currentToast?.title, "Berhasil")
        XCTAssertEqual(sut.alertCoordinator.currentToast?.style, .success)

        sut.showToast(title: "Peringatan", message: "Periksa kembali", style: .warning)
        XCTAssertEqual(sut.alertCoordinator.currentToast?.title, "Peringatan")
        XCTAssertEqual(sut.alertCoordinator.currentToast?.style, .warning)

        sut.alertCoordinator.dismissToast()
        XCTAssertNil(sut.alertCoordinator.currentToast)
    }

    func test_toastStyle_and_toastMessage() {
        let styles: [ToastMessage.ToastStyle] = [.info, .success, .warning, .error]
        for style in styles {
            XCTAssertNotNil(style.color)
            XCTAssertFalse(style.iconName.isEmpty)
        }

        let customID = UUID()
        let customToast = ToastMessage(id: customID, title: "Test", message: "Msg", style: .error, duration: 1.0)
        XCTAssertEqual(customToast.id, customID)
        XCTAssertEqual(customToast.duration, 1.0)
    }

    // MARK: - DeepLink Resolving

    func test_deepLinkResolve_resolvesProductListAndDetail() {
        // ProductRoute
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product"]), .product(.list))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["products"]), .product(.list))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "42"]), .product(.detail(id: 42)))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "preload", "42"]), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product-preload", "42"]), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["products-preload"]), .deeplinkFetch(.general))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "preload"]), .deeplinkFetch(.general))
        XCTAssertEqual(ProductRoute.deepLinkResolve(pathComponents: ["product", "detail", "50"]), .product(.detail(id: 50)))

        // FavoritesRoute
        XCTAssertEqual(FavoritesRoute.deepLinkResolve(pathComponents: ["favorites"]), .favorites(.list))
        XCTAssertEqual(FavoritesRoute.deepLinkResolve(pathComponents: ["favorite"]), .favorites(.list))
        XCTAssertNil(FavoritesRoute.deepLinkResolve(pathComponents: ["unknown"]))

        // CartRoute
        XCTAssertEqual(CartRoute.deepLinkResolve(pathComponents: ["cart"]), .cart(.list))
        XCTAssertNil(CartRoute.deepLinkResolve(pathComponents: ["unknown"]))

        // AppRoute
        XCTAssertEqual(AppRoute.deepLinkResolve(pathComponents: ["splash"]), .splash)
        XCTAssertNil(AppRoute.deepLinkResolve(pathComponents: ["unknown"]))
    }

    func test_deepLinkHandler_parse_resolvesRoutesDirectly() {
        let handler = DeepLinkHandler()

        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product")!), .product(.list))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/42")!), .product(.detail(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product-preload/42")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/preload/42")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://favorites")!), .favorites(.list))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://cart")!), .cart(.list))
        XCTAssertNil(handler.parse(url: URL(string: "mytuist://unknown")!))
    }

    func test_deepLinkHandler_parse_withQueryParameters() {
        let handler = DeepLinkHandler()

        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product?id=42")!), .product(.detail(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product?product_id=42")!), .product(.detail(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product?productid=42")!), .product(.detail(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/detail?id=42")!), .product(.detail(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product?id=42&preload=true")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product?preload=42")!), .deeplinkFetch(.product(id: 42)))
        XCTAssertEqual(handler.parse(url: URL(string: "mytuist://product/preload?id=42")!), .deeplinkFetch(.product(id: 42)))
    }

    func test_handleURL_navigatesToResolvedRoute() {
        sut.setRootView(to: .splash)

        let url = URL(string: "mytuist://product/99")!
        sut.handle(url: url)

        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .product(.detail))
    }

    func test_handleURL_deeplinkFetch_triggersDeeplinkLoader() {
        let mockNav = MockNavigationController()
        let router = AppRouter(navigationController: mockNav)
        let url = URL(string: "mytuist://product-preload/10")!
        router.handle(url: url)
        XCTAssertEqual(mockNav.presentCallCount, 1)
        XCTAssertNotNil(router.navigationController.presentedViewController)
    }

    // MARK: - Presentation Detents & Configuration

    func test_presentationDetents_and_sheetConfiguration() {
        let detents: [AppPresentationDetent] = [
            .medium,
            .large,
            .fraction(0.3),
            .fraction(0.8),
            .height(200),
            .height(550)
        ]

        for detent in detents {
            XCTAssertNotNil(detent.uiKitDetent)
            XCTAssertNotNil(detent.uiKitIdentifier)
        }

        let dragIndicators: [SheetDragIndicator] = [.automatic, .visible, .hidden]
        for indicator in dragIndicators {
            let config = SheetConfiguration(dragIndicator: indicator)
            XCTAssertEqual(config.dragIndicator, indicator)
        }

        let transparentConfig = SheetConfiguration.transparent(
            detents: [.medium],
            selectedDetent: .medium,
            dragIndicator: .automatic,
            cornerRadius: 12,
            largestUndimmedDetent: .medium
        )
        XCTAssertTrue(transparentConfig.isTransparent)
        XCTAssertEqual(transparentConfig.cornerRadius, 12)
    }

    // MARK: - Routes, Destinations, and Param

    func test_routes_destinations_and_params() {
        // Cart
        let cartParam = CartScreenParam()
        let customCartParam = CartScreenParam(id: "cart-123")
        XCTAssertEqual(customCartParam.id, "cart-123")
        XCTAssertFalse(cartParam.id.isEmpty)

        let checkoutParam = CheckoutScreenParam()
        let customCheckoutParam = CheckoutScreenParam(id: "chk-456")
        XCTAssertEqual(customCheckoutParam.id, "chk-456")
        XCTAssertFalse(checkoutParam.id.isEmpty)

        XCTAssertEqual(CartRoute.list.destination, .cart(.list))
        XCTAssertEqual(CartRoute.detail(customCartParam).destination, .cart(.list))
        XCTAssertEqual(CartRoute.checkout(customCheckoutParam).destination, .cart(.checkout))

        _ = CartRoute.list.makeView()
        _ = CartRoute.detail(customCartParam).makeView()
        _ = CartRoute.checkout(customCheckoutParam).makeView()

        // Favorites
        XCTAssertEqual(FavoritesRoute.list.destination, .favorites(.list))
        _ = FavoritesRoute.list.makeView()

        // Product
        let productParam = ProductScreenParam(id: 1, title: "Item", price: 10.0)
        XCTAssertEqual(ProductRoute.list.destination, .product(.list))
        XCTAssertEqual(ProductRoute.detail(productParam).destination, .product(.detail))
        XCTAssertEqual(ProductRoute.detail(id: 99), .detail(.init(id: 99)))
        XCTAssertEqual(ProductRoute.detailById(99), .detail(.init(id: 99)))

        _ = ProductRoute.list.makeView()
        _ = ProductRoute.detail(productParam).makeView()

        // AppRoute Destinations & SheetConfigs
        XCTAssertEqual(AppRoute.splash.destination, .splash)
        XCTAssertEqual(AppRoute.deeplinkFetch(.general).destination, .deeplinkFetch)
        XCTAssertEqual(AppRoute.deeplinkFetch(.custom(name: "test")).destination, .deeplinkFetch)
        XCTAssertEqual(AppRoute.product(.list).destination, .product(.list))
        XCTAssertEqual(AppRoute.favorites(.list).destination, .favorites(.list))
        XCTAssertEqual(AppRoute.cart(.list).destination, .cart(.list))
        XCTAssertNil(AppRoute.splash.sheetConfiguration)

        _ = AppRoute.splash.makeView()
        _ = AppRoute.deeplinkFetch(.general).makeView()
        _ = AppRoute.product(.list).makeView()
        _ = AppRoute.favorites(.list).makeView()
        _ = AppRoute.cart(.list).makeView()

        // RouteHostingController
        let hosting = RouteHostingController(rootView: Text("Test"), routeDestination: .splash)
        XCTAssertEqual(hosting.routeDestination, .splash)

        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.finishEncoding()
        if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: archiver.encodedData) {
            let coderHosting = RouteHostingController<Text>(coder: unarchiver)
            XCTAssertNil(coderHosting)
        }
    }

    func test_appRouteType_defaultExtensions() {
        XCTAssertNil(DummyRoute.first.sheetConfiguration)
        XCTAssertNil(DummyRoute.deepLinkHost)
        XCTAssertNil(DummyRoute.deepLinkResolve(pathComponents: ["unknown"]))
        XCTAssertNil(DummyRoute.deepLinkResolve(pathComponents: ["unknown"], queryParameters: ["foo": "bar"]))
    }

    func test_appRouteDestination_equality_and_hashing() {
        let allDestinations: [AppRouteDestination] = [
            .splash,
            .productList,
            .productDetail,
            .deeplinkFetch,
            .product(.list),
            .product(.detail),
            .favorites(.list),
            .cart(.list),
            .cart(.checkout)
        ]

        for d1 in allDestinations {
            for d2 in allDestinations {
                if d1 == d2 {
                    XCTAssertEqual(d1.hashValue, d2.hashValue)
                } else {
                    XCTAssertNotEqual(d1, d2)
                }
            }
        }
    }

    // MARK: - Container & Extensions

    func test_container_router() {
        let router = Container.shared.router()
        XCTAssertNotNil(router)
        let secondRouter = Container.shared.router()
        XCTAssertTrue(router === secondRouter)
    }

    func test_navigationController_swipeBackExtension() {
        let nav = UINavigationController()
        _ = nav.view // trigger viewDidLoad
        XCTAssertFalse(nav.gestureRecognizerShouldBegin(UIGestureRecognizer()))

        nav.viewControllers = [UIViewController(), UIViewController()]
        XCTAssertTrue(nav.gestureRecognizerShouldBegin(UIGestureRecognizer()))
    }

    func test_navigationContainer_and_lazyView() {
        let container = NavigationControllerContainer(navigationController: sut.navigationController)
        let hosting = UIHostingController(rootView: container)
        _ = hosting.view

        let lazy = LazyView(Text("Lazy Text"))
        _ = lazy.body
    }
}
