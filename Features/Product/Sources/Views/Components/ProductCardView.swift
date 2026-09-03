import SwiftUI
import DomainProduct
import CoreDesignSystem

public struct ProductCardView: View {
    private let product: Product

    public init(product: Product) {
        self.product = product
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                AsyncRemoteImage(urlString: product.image, contentMode: .fit)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.sm)
                    .background(Color.white)
                    .cornerRadius(DesignTokens.CornerRadius.md)

                // Rating Badge
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(DesignTokens.Colors.accent)
                    Text(String(format: "%.1f", product.rating.rate))
                        .font(.caption2.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .cornerRadius(DesignTokens.CornerRadius.sm)
                .padding(DesignTokens.Spacing.xs)
            }

            // Category tag
            Text(product.category.uppercased())
                .font(.caption2.bold())
                .foregroundColor(DesignTokens.Colors.secondary)
                .lineLimit(1)

            // Title
            Text(product.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 38, alignment: .topLeading)

            // Price
            Text(product.formattedPrice)
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.primary)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.CornerRadius.md)
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}
