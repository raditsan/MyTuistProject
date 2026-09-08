import XCTest
import SwiftUI
import CoreNavigation
import FactoryKit
@testable import FeatureCart

@MainActor
final class CheckoutViewModelTests: XCTestCase {
    private var sut: CheckoutViewModel!
    private var router: AppRouter!

    override func setUp() {
        super.setUp()
        let nav = UINavigationController()
        router = AppRouter(navigationController: nav)
        Container.shared.router.register {
            MainActor.assumeIsolated {
                self.router
            }
        }
        sut = CheckoutViewModel()
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    func test_initialState() {
        XCTAssertNotNil(sut)
    }

    func test_goBack_callsRouterPop() {
        router.push(Text("Screen 1"), animated: false)
        router.push(Text("Screen 2"), animated: false)
        XCTAssertEqual(router.navigationController.viewControllers.count, 2)

        sut.goBack()
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
    }
}
