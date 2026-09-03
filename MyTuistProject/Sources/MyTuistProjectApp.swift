import SwiftUI
import CoreNavigation

@main
struct MyTuistProjectApp: App {
    @StateObject private var router = AppDIContainer.shared.router

    init() {
        AppDIContainer.shared.router.setRootView(to: AppRoute.productList)
    }

    var body: some Scene {
        WindowGroup {
            NavigationControllerContainer(navigationController: router.navigationController)
                .ignoresSafeArea()
                .environmentObject(router)
                .environmentObject(router.alertCoordinator)
        }
    }
}
