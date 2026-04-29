import SwiftUI

struct ImageGenerationView: View {
    @StateObject private var generator = ImageGenerator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                ModelStatusView(
                    title: "生成模型待接入",
                    message: "当前保留 prompt、加载和结果展示。正式商用前建议接入已确认许可证的 Stable Diffusion Core ML 或自研模型。",
                    tone: .warning
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Prompt")
                        .font(.headline)
                    TextEditor(text: $generator.prompt)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityLabel("图像生成提示词")
                }
                .padding(16)
                .cardSurface()

                Button {
                    Task { await generator.generate() }
                } label: {
                    Label(generator.isGenerating ? "生成中" : "生成预览", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(generator.isGenerating)

                VStack(alignment: .leading, spacing: 12) {
                    Text(generator.status)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityLabel("图像生成状态：\(generator.status)")

                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .fill(Color(.tertiarySystemGroupedBackground))

                        if let image = generator.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .accessibilityLabel("生成图像预览")
                        } else {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 54, weight: .light))
                                .foregroundStyle(AppTheme.accent)
                                .accessibilityHidden(true)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                }
                .padding(16)
                .cardSurface()
            }
            .padding(AppTheme.spacing)
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("图像生成")
        .navigationBarTitleDisplayMode(.inline)
    }
}
