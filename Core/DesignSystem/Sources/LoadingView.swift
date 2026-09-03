import SwiftUI

public struct LoadingView: View {
    private let message: String

    public init(message: String = "Memuat data...") {
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
