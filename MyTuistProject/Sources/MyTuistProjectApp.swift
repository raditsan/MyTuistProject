import SwiftUI
import FeatureProduct

@main
struct MyTuistProjectApp: App {
    @StateObject private var container = AppDIContainer.shared

    var body: some Scene {
        WindowGroup {
            container.makeProductListView()
        }
    }
}
