import SwiftUI
import CoreLocalization

public struct LoadingView: View {
    public let message: String

    public init(message: String = L10n.Common.loading) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignTokens.Colors.primary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
