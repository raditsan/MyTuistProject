import SwiftUI

// MARK: - ViewDidLoadModifier

/// A ViewModifier that triggers an action exactly once when the view first appears.
///
/// Unlike `.onAppear`, which fires every time a view reappears (such as navigating back from
/// another screen or switching tabs), `.onLoad` executes only once for the lifecycle of the view.
public struct ViewDidLoadModifier: ViewModifier {
    @State private var hasLoaded = false
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public func body(content: Content) -> some View {
        content.onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            action()
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Executes a synchronous action only once when the view first appears.
    ///
    /// - Parameter action: Closure to execute on the view's initial load.
    /// - Returns: A modified view that calls the action once.
    func onLoad(perform action: @escaping () -> Void) -> some View {
        modifier(ViewDidLoadModifier(action: action))
    }

    /// Executes an asynchronous action (Swift Concurrency) only once when the view first appears.
    ///
    /// - Parameter action: An async closure to execute on the view's initial load.
    /// - Returns: A modified view that calls the async task once.
    func onLoad(perform action: @escaping () async -> Void) -> some View {
        modifier(ViewDidLoadModifier {
            _Concurrency.Task {
                await action()
            }
        })
    }
}
