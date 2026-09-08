import SwiftUI
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import FactoryKit

@MainActor
public struct CheckoutView: View {
    @Injected(\.router) private var router
    @StateObject private var viewModel: CheckoutViewModel

    public init(param: CheckoutScreenParam? = nil) {
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(param: param))
    }

    public init(viewModel: CheckoutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Checkout Screen")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Checkout")
    }
}
