import Foundation

/// Navigation parameter for Cart screen.
/// Kept in CoreNavigation without any dependency to Domain entities.
public struct CartScreenParam: Identifiable, Hashable, Sendable {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}
