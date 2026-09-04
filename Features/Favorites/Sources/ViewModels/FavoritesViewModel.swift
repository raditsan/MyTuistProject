import Foundation
import Combine
import CoreNavigation
import FactoryKit

@MainActor
public final class FavoritesViewModel: ObservableObject {
    @Injected(\.router) private var router: AppRouter
    @Published public var items: [String] = []

    public init() {}

    public func loadFavorites() {
        items = ["MacBook Pro", "AirPods Max", "iPad Air"]
    }

    public func goBack() {
        router.pop()
    }
}
