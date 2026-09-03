import SwiftUI
import CoreNavigation
import FactoryKit

@main
struct MyTuistProjectApp: App {
    @Injected(\.router) private var router

    init() {
        AppDIContainer.shared.setupNavigation()
        Container.shared.router().setRootView(to: .productList)
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
