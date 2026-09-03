import Foundation
import CoreNavigation

public enum DeeplinkFlowFactory {
    @MainActor
    public static func makeFlow(for entryPoint: DeeplinkEntryPoint) -> any DeeplinkFlow {
        switch entryPoint {
        case .general, .custom:
            return DefaultDeeplinkFlow()
        case .product(let id):
            return ProductDetailDeeplinkFlow(productId: id)
        }
    }
}
