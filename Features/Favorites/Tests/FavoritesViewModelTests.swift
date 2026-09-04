import XCTest
import SwiftUI
import CoreNavigation
import FactoryKit
@testable import FeatureFavorites

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    private var sut: FavoritesViewModel!
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
        sut = FavoritesViewModel()
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    func test_initialState_isEmpty() {
        XCTAssertTrue(sut.items.isEmpty)
    }

    func test_loadFavorites_populatesItems() {
        sut.loadFavorites()
        XCTAssertEqual(sut.items.count, 3)
        XCTAssertTrue(sut.items.contains("MacBook Pro"))
    }

    func test_goBack_callsRouterPop() {
        router.push(Text("Screen 1"), animated: false)
        router.push(Text("Screen 2"), animated: false)
        XCTAssertEqual(router.navigationController.viewControllers.count, 2)

        sut.goBack()
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
    }
}
