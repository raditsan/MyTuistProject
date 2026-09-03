import SwiftUI
import CoreNavigation
import CoreDesignSystem
import FactoryKit

@MainActor
public struct DeeplinkLoaderView: View {
    @Injected(\.router) private var router: AppRouter
    @StateObject private var viewModel: DeeplinkLoaderViewModel

    public init(entryPoint: DeeplinkEntryPoint = .general) {
        _viewModel = StateObject(wrappedValue: DeeplinkLoaderViewModel(entryPoint: entryPoint))
    }

    public init(flow: any DeeplinkFlow) {
        _viewModel = StateObject(wrappedValue: DeeplinkLoaderViewModel(flow: flow))
    }

    public var body: some View {
        ZStack {
            DesignTokens.Colors.background.opacity(0.25)
                .ignoresSafeArea()

            if viewModel.isLoading {
                renderLoading
            } else if let errorMessage = viewModel.errorMessage {
                renderError(message: errorMessage)
            }
        }
        .task {
            await viewModel.execute()
        }
    }

    // MARK: - Subviews

    private var renderLoading: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(DesignTokens.Colors.primary)

            Text(viewModel.loadingMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }

    private func renderError(message: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(DesignTokens.Colors.accent)

            Text("Gagal Memuat Halaman")
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.md)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("Kembali") {
                    if router.navigationController.viewControllers.count > 1 {
                        router.pop()
                    } else {
                        router.setRootView(to: .product(.list))
                    }
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.textSecondary)

                Button("Coba Lagi") {
                    viewModel.retry(router: router)
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignTokens.Colors.primary)
            }
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}
