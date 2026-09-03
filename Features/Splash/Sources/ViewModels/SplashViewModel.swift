import Foundation
import Combine
import CoreNavigation
import FactoryKit

@MainActor
public final class SplashViewModel: ObservableObject {
    @Injected(\.router) private var router: AppRouter
    @Published public var isAnimating = false

    public init() {}

    public func onAppear(delayNanoseconds: UInt64 = 1_500_000_000) {
        isAnimating = true

        Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            router.setRootView(to: .product(.list))
        }
    }
}
