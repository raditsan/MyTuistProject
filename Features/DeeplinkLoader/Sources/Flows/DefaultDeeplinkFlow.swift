import Foundation
import CoreNavigation
import FactoryKit

/// Fallback flow umum
@MainActor
public final class DefaultDeeplinkFlow: DeeplinkFlow {
    @Injected(\.router) private var router
    public init() {}

    public func execute(update: @escaping DeeplinkFlowUpdate) async {
        update(.setLoading(true, message: "Memproses link..."))
        update(.setError(nil))

        try? await Task.sleep(nanoseconds: 600_000_000)

        update(.setLoading(false, message: nil))
        await router.dismissDeeplinkLoader()
        router.setRootView(to: .product(.list))
    }
}
