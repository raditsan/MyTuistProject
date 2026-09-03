import SwiftUI
import Combine

@MainActor
public final class AlertCoordinator: ObservableObject {
    @Published public var currentToast: ToastMessage?

    public init() {}

    public func showToast(_ toast: ToastMessage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.currentToast = toast
        }

        Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            if self.currentToast?.id == toast.id {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentToast = nil
                }
            }
        }
    }

    public func dismissToast() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentToast = nil
        }
    }
}
