import SwiftUI

struct FeatureCard: View {
    let feature: FeatureDestination

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(feature.tint.opacity(0.16))

                Image(systemName: feature.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(feature.tint)
                    .accessibilityHidden(true)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(feature.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(feature.badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(feature.tint.opacity(0.12))
                        .foregroundStyle(feature.tint)
                        .clipShape(Capsule())
                }

                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 10)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(minHeight: 88)
        .cardSurface()
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(feature.title)
        .accessibilityHint(feature.subtitle)
    }
}
