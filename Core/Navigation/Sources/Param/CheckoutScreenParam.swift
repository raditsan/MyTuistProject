import Foundation

/// Navigation parameter for Checkout screen.
/// Kept in CoreNavigation without any dependency to Domain entities.
public struct CheckoutScreenParam: Identifiable, Hashable, Sendable {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}
