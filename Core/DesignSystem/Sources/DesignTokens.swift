import SwiftUI

public enum DesignTokens {
    public enum Colors {
        public static let primary = Color.blue
        public static let secondary = Color.indigo
        public static let background = Color(UIColor.systemGroupedBackground)
        public static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
        public static let textPrimary = Color(UIColor.label)
        public static let textSecondary = Color(UIColor.secondaryLabel)
        public static let accent = Color.orange
        public static let success = Color.green
        public static let error = Color.red
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let full: CGFloat = 999
    }
}
