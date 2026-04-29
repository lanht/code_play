import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.49, green: 0.23, blue: 0.93)
    static let secondary = Color(red: 0.39, green: 0.40, blue: 0.95)
    static let accent = Color(red: 0.93, green: 0.28, blue: 0.60)
    static let success = Color(red: 0.06, green: 0.58, blue: 0.38)
    static let warning = Color(red: 0.86, green: 0.45, blue: 0.10)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let pageBackground = Color(.systemGroupedBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)

    static let cardRadius: CGFloat = 18
    static let spacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    static let minimumTapTarget: CGFloat = 44
}

extension View {
    func cardSurface() -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
            }
    }
}
