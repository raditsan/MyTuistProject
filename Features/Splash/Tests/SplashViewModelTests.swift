import XCTest
import CoreNavigation
import FactoryKit
@testable import FeatureSplash

@MainActor
final class SplashViewModelTests: XCTestCase {
    private var sut: SplashViewModel!

    override func setUp() {
        super.setUp()
        Container.shared.router.register {
            MainActor.assumeIsolated {
                let router = AppRouter(navigationController: UINavigationController())
                router.setRootView(to: .splash)
                return router
            }
        }
        sut = SplashViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_initialState_isNotAnimating() {
        XCTAssertFalse(sut.isAnimating)
    }

    func test_onAppear_setsIsAnimatingToTrue() {
        sut.onAppear(delayNanoseconds: 100_000)
        XCTAssertTrue(sut.isAnimating)
    }

    func test_onAppear_navigatesToProductListAfterDelay() async {
        let router = Container.shared.router()
        sut.onAppear(delayNanoseconds: 20_000_000)

        try? await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
        let rootVC = router.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .product(.list))
    }

    func test_cancel_abortsNavigation() async {
        let router = Container.shared.router()
        sut.onAppear(delayNanoseconds: 50_000_000)

        // Langsung cancel sebelum delay selesai
        sut.cancel()

        try? await Task.sleep(nanoseconds: 80_000_000)

        // Navigasi tidak boleh tereksekusi (tetap di splash)
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
        let rootVC = router.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .splash)
    }

    func test_onAppear_doesNotNavigateIfSplashIsNoLongerActive() async {
        let router = Container.shared.router()
        router.setRootView(to: .splash)

        sut.onAppear(delayNanoseconds: 50_000_000)

        // Simulasikan deep link tiba di tengah-tengah delay splash (misal ke cart)
        router.setRootView(to: .cart(.list))

        try? await Task.sleep(nanoseconds: 80_000_000)

        // Stack tetap berada di cart, tidak di-overwrite kembali oleh splash ke product list
        let currentRoot = router.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(currentRoot?.routeDestination, .cart(.list))
    }

    func test_onAppear_withPendingDeepLink_navigatesToTargetAfterSplashCompletes() async {
        let router = Container.shared.router()
        router.setRootView(to: .splash)

        // Deep link tiba saat splash sedang tampil & loading config
        router.handle(url: URL(string: "mytuist://product/42")!)

        // Layar masih splash, belum berpindah ke detail
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
        XCTAssertNotNil(router.pendingDeepLinkRoute)

        // Splash onAppear berjalan menunggu delay / API config
        sut.onAppear(delayNanoseconds: 20_000_000)

        try? await Task.sleep(nanoseconds: 80_000_000)

        // Setelah splash selesai, otomatis beralih ke ProductList dan membuka ProductDetail
        XCTAssertEqual(router.navigationController.viewControllers.count, 2)
        let rootVC = router.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .product(.list))
        let topVC = router.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .product(.detail))
        XCTAssertNil(router.pendingDeepLinkRoute)
    }
}
