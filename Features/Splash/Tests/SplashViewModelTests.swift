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
                AppRouter(navigationController: UINavigationController())
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
}
