import SwiftUI
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import FactoryKit

@MainActor
public struct CartView: View {
    @Injected(\.router) private var router
    @StateObject private var viewModel: CartViewModel

    public init(param: CartScreenParam? = nil) {
        _viewModel = StateObject(wrappedValue: CartViewModel(param: param))
    }

    public init(viewModel: CartViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Cart Screen")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Cart")
    }
}
