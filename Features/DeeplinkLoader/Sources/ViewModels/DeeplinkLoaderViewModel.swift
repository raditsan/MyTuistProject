import Combine
import Foundation
import CoreNavigation

@MainActor
public final class DeeplinkLoaderViewModel: ObservableObject {
    @Published public var isLoading: Bool = true
    @Published public var loadingMessage: String = "Memuat data..."
    @Published public var errorMessage: String?

    public let flow: any DeeplinkFlow

    public init(flow: any DeeplinkFlow) {
        self.flow = flow
    }

    public convenience init(entryPoint: DeeplinkEntryPoint = .general) {
        self.init(flow: DeeplinkFlowFactory.makeFlow(for: entryPoint))
    }

    public func execute() async {
        await flow.execute { [weak self] action in
            self?.apply(action)
        }
    }

    public func retry(router: AppRouter) {
        Task {
            await execute()
        }
    }

    private func apply(_ action: DeeplinkFlowUIAction) {
        switch action {
        case let .setLoading(isLoading, message):
            self.isLoading = isLoading
            if let message = message {
                self.loadingMessage = message
            }
        case let .setError(error):
            self.errorMessage = error
        }
    }
}
