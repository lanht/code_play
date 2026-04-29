import PhotosUI
import SwiftUI

struct ImageRecognitionView: View {
    @StateObject private var classifier = ImageClassifier()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                ModelStatusView(
                    title: "图像识别已启用",
                    message: "当前使用内置 MobileNetV2 模型，结果优先显示中文，并保留英文原始标签用于校验。",
                    tone: .success
                )

                imagePreview

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("选择图片", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("从照片图库选择一张图片进行 Core ML 识别")

                resultSection
            }
            .padding(AppTheme.spacing)
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("图像识别")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, item in
            Task { await loadImage(from: item) }
        }
    }

    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .fill(AppTheme.surface)

            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                    .accessibilityLabel("待识别图片")
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundStyle(AppTheme.primary)
                    Text("选择一张图片开始识别")
                        .font(.headline)
                    Text("结果会显示中文标签、原始英文标签和置信度。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.2, contentMode: .fit)
        .cardSurface()
    }

    @ViewBuilder
    private var resultSection: some View {
        switch classifier.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("正在分析图片")
                .frame(maxWidth: .infinity, minHeight: 80)
                .cardSurface()
        case .ready(let results):
            VStack(alignment: .leading, spacing: 12) {
                Text("识别结果")
                    .font(.headline)
                ForEach(results) { result in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.localizedLabel)
                                    .font(.subheadline.weight(.semibold))

                                Text(result.label)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .accessibilityElement(children: .combine)

                            Spacer()

                            Text(result.confidence, format: .percent.precision(.fractionLength(1)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        ProgressView(value: result.confidence)
                            .tint(AppTheme.primary)
                    }
                }
            }
            .padding(16)
            .cardSurface()
        case .failed(let message):
            ModelStatusView(title: "暂不可识别", message: message, tone: .warning)
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }

        selectedImage = uiImage
        await classifier.classify(uiImage)
    }
}
