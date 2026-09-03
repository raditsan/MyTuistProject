import SwiftUI
import DomainProduct
import CoreDesignSystem
import CoreNavigation
import FactoryKit

@MainActor
public struct ProductDetailView: View {
    @Injected(\.router) private var router
    @StateObject private var viewModel: ProductDetailViewModel

    @MainActor
    public init(productId: Int) {
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: productId))
    }

    @MainActor
    public init(viewModel: ProductDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Memuat detail produk...")
            case .empty:
                ErrorView(title: "Tidak Ditemukan", message: "Detail produk tidak ditemukan.")
            case .failure(let errorMessage):
                ErrorView(
                    title: "Gagal Memuat Detail",
                    message: errorMessage,
                    retryAction: {
                        Task { await viewModel.loadDetail() }
                    }
                )
            case .success(let product):
                productDetailContent(product: product)
            }
        }
        .navigationTitle("Detail Produk")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDetail()
        }
    }

    @ViewBuilder
    private func productDetailContent(product: Product) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Image
                AsyncRemoteImage(urlString: product.image, contentMode: .fit)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.md)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.CornerRadius.lg)

                // Category & Rating
                HStack {
                    Text(product.category.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(DesignTokens.Colors.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DesignTokens.Colors.secondary.opacity(0.12))
                        .cornerRadius(DesignTokens.CornerRadius.sm)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(DesignTokens.Colors.accent)
                        Text(String(format: "%.1f", product.rating.rate))
                            .bold()
                        Text("(\(product.rating.count) ulasan)")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .font(.subheadline)
                }

                // Title
                Text(product.title)
                    .font(.title3.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                // Price
                Text(product.formattedPrice)
                    .font(.title.bold())
                    .foregroundColor(DesignTokens.Colors.primary)

                Divider()
                    .padding(.vertical, DesignTokens.Spacing.xs)

                // Description
                Text("Deskripsi")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(product.description)
                    .font(.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background.ignoresSafeArea())
    }
}
