import SwiftUI
import DomainProduct
import CoreDesignSystem
import CoreNavigation
import FactoryKit

@MainActor
public struct ProductListView: View {
    @Injected(\.router) private var router
    @StateObject private var viewModel: ProductListViewModel

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
    ]

    public init() {
        _viewModel = StateObject(wrappedValue: ProductListViewModel())
    }

    public init(viewModel: ProductListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Category Filter Bar
            categoryFilterBar

            // Content State
            contentView
        }
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Katalog Produk")
        .searchable(text: $viewModel.searchQuery, prompt: "Cari produk...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    router.navigate(.favorites(.list))
                } label: {
                    Image(systemName: "heart.fill")
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                .accessibilityLabel("Menu Favorit")
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Category Filter Bar
    @ViewBuilder
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category
                    Button(action: {
                        Task {
                            await viewModel.selectCategory(category)
                        }
                    }) {
                        Text(category.capitalized)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.cardBackground
                            )
                            .cornerRadius(DesignTokens.CornerRadius.full)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: "Mengambil daftar produk...")
        case .empty:
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text("Tidak ada produk yang ditemukan")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Text("Coba gunakan kata kunci pencarian atau kategori lain.")
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        case .failure(let errorMessage):
            ErrorView(
                title: "Gagal Memuat Produk",
                message: errorMessage,
                retryAction: {
                    Task { await viewModel.refresh() }
                }
            )
        case .success(let products):
            ScrollView {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                    ForEach(products) { product in
                        Button {
                            router.navigate(.product(.detail(product)))
                        } label: {
                            ProductCardView(product: product)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}
