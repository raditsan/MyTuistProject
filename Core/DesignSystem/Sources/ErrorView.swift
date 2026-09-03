import SwiftUI

public struct ErrorView: View {
    private let title: String
    private let message: String
    private let retryAction: (() -> Void)?

    public init(
        title: String = "Terjadi Kesalahan",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.error)

            Text(title)
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.lg)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Coba Lagi", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(DesignTokens.CornerRadius.md)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
