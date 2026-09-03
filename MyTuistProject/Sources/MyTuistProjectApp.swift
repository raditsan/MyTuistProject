import SwiftUI
import CoreNavigation
import FeatureProduct
import FactoryKit

@main
struct MyTuistProjectApp: App {
    @Injected(\.router) private var router

    init() {
        _ = AppDIContainer.shared
        Container.shared.router().setRootView(to: .splash)
    }

    var body: some Scene {
        WindowGroup {
            NavigationControllerContainer(navigationController: router.navigationController)
                .ignoresSafeArea()
                .environmentObject(router)
                .environmentObject(router.alertCoordinator)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}
