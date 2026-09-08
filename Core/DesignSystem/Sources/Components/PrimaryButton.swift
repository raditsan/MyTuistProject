import SwiftUI

public struct PrimaryButton: View {
    public let title: String
    public let action: (() -> Void)?

    public init(
        title: String,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: {
            action?()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(DesignTokens.Colors.background)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.primary)
                .cornerRadius(DesignTokens.CornerRadius.md)
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        PrimaryButton(title: "Sample PrimaryButton")
    }
    .padding()
}
