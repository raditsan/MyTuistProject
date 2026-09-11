import Foundation
import Combine
import CoreNavigation
import FactoryKit

@MainActor
public final class SplashViewModel: ObservableObject {
    @Injected(\.router) private var router
    @Published public var isAnimating = false
    private var transitionTask: Task<Void, Never>?

    public init() {}

    public func onAppear(delayNanoseconds: UInt64 = 1_500_000_000) {
        guard router.isSplashActive else { return }
        isAnimating = true

        transitionTask?.cancel()
        transitionTask = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            guard router.isSplashActive else { return }
            router.setRootView(to: .product(.list))
            router.completeSplash()
        }
    }

    public func cancel() {
        transitionTask?.cancel()
        transitionTask = nil
    }

    deinit {
        transitionTask?.cancel()
    }
}
