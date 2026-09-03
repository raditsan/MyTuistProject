import Foundation
import SwiftUI
import CoreNavigation

// MARK: - Flow UI Actions & Types

public typealias DeeplinkFlowUpdate = @Sendable @MainActor (DeeplinkFlowUIAction) -> Void

public enum DeeplinkFlowUIAction: Sendable {
    case setLoading(Bool, message: String? = nil)
    case setError(String?)
}

// MARK: - Flow Protocol

@MainActor
public protocol DeeplinkFlow {
    func execute(update: @escaping DeeplinkFlowUpdate) async
}
