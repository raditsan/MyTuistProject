import Testing
import SwiftUI
import CoreNavigation
@testable import MyTuistProject

@MainActor
struct MyTuistProjectTests {

    @Test func testRouteHandlers() {
        _ = AppDIContainer.shared

        // Splash Route Handler
        let splashView = SplashRouteHandler.buildView()
        #expect(type(of: splashView) == AnyView.self)

        // Deeplink Route Handler
        let deeplinkView = DeeplinkRouteHandler.buildView(for: .general)
        #expect(type(of: deeplinkView) == AnyView.self)

        // Product Route Handler
        let productListView = ProductRouteHandler.buildView(for: .list)
        #expect(type(of: productListView) == AnyView.self)

        let productDetailView = ProductRouteHandler.buildView(for: .detail(.init(id: 1)))
        #expect(type(of: productDetailView) == AnyView.self)

        // Favorites Route Handler
        let favoritesView = FavoritesRouteHandler.buildView(for: .list)
        #expect(type(of: favoritesView) == AnyView.self)
    }

    @Test func testAppRouterViewBuilderIntegration() {
        _ = AppDIContainer.shared

        let viewSplash = AppRouter.viewBuilder(.splash)
        #expect(type(of: viewSplash) == AnyView.self)

        let viewProduct = AppRouter.viewBuilder(.product(.list))
        #expect(type(of: viewProduct) == AnyView.self)

        let viewFavorites = AppRouter.viewBuilder(.favorites(.list))
        #expect(type(of: viewFavorites) == AnyView.self)

        let viewDeeplink = AppRouter.viewBuilder(.deeplinkFetch(.general))
        #expect(type(of: viewDeeplink) == AnyView.self)
    }
}
