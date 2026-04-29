import SwiftUI

struct HomeView: View {
    @State private var showsCommercialNotes = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.largeSpacing) {
                    header

                    trustStrip

                    VStack(spacing: 12) {
                        ForEach(FeatureDestination.allCases) { feature in
                            NavigationLink(value: feature) {
                                FeatureCard(feature: feature)
                            }
                            .buttonStyle(.plain)
                            .sensoryFeedback(.selection, trigger: feature.id)
                        }
                    }

                    ModelStatusView(
                        title: "商用集成状态",
                        message: "图像识别已内置 Apple 官方 MobileNetV2；语音转写使用系统 Speech；图像生成保留模型管线入口，接入前需确认模型许可证、体积和设备性能。",
                        tone: .info
                    )

                    commercialChecklist
                }
                .padding(.horizontal, AppTheme.spacing)
                .padding(.vertical, AppTheme.largeSpacing)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("AIAssistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsCommercialNotes = true
                    } label: {
                        Image(systemName: "shield.lefthalf.filled")
                            .accessibilityLabel("商用说明")
                    }
                }
            }
            .sheet(isPresented: $showsCommercialNotes) {
                CommercialNotesView()
            }
            .navigationDestination(for: FeatureDestination.self) { feature in
                switch feature {
                case .imageRecognition:
                    ImageRecognitionView()
                case .speechProcessing:
                    SpeechProcessingView()
                case .imageGeneration:
                    ImageGenerationView()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AIAssistant")
                        .font(.title.weight(.bold))

                    Text("端侧智能工具套件")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Label("On-device", systemImage: "lock.shield")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: AppTheme.minimumTapTarget)
                    .background(AppTheme.primary.opacity(0.12))
                    .foregroundStyle(AppTheme.primary)
                    .clipShape(Capsule())
            }

            Text("面向正式发布的 AI 助手基础版：图像识别、语音处理与生成式能力统一收口，默认优先在设备侧运行，降低隐私和云端成本风险。")
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .padding(20)
        .background {
            LinearGradient(
                colors: [AppTheme.primary.opacity(0.20), AppTheme.accent.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(AppTheme.primary.opacity(0.16))
                .padding(18)
                .accessibilityHidden(true)
        }
    }

    private var trustStrip: some View {
        HStack(spacing: 10) {
            TrustBadge(title: "隐私优先", systemImage: "lock.fill", tint: AppTheme.success)
            TrustBadge(title: "模型可替换", systemImage: "arrow.triangle.2.circlepath", tint: AppTheme.secondary)
            TrustBadge(title: "离线友好", systemImage: "wifi.slash", tint: AppTheme.accent)
        }
    }

    private var commercialChecklist: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("上线前检查")
                .font(.headline)

            CommercialCheckRow(title: "权限透明", detail: "照片、麦克风、语音识别权限均已配置用途说明。", state: .ready)
            CommercialCheckRow(title: "模型来源", detail: "MobileNetV2 来自 Apple 官方模型库；其他模型需补充许可证审查。", state: .ready)
            CommercialCheckRow(title: "生成能力", detail: "图像生成当前是占位预览，接入 Stable Diffusion Core ML 后再开放生产入口。", state: .pending)
        }
        .padding(16)
        .cardSurface()
    }
}

private struct TrustBadge: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapTarget)
            .background(tint.opacity(0.10))
            .foregroundStyle(tint)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct CommercialCheckRow: View {
    let title: String
    let detail: String
    let state: State

    enum State {
        case ready
        case pending

        var icon: String {
            switch self {
            case .ready: "checkmark.circle.fill"
            case .pending: "clock.fill"
            }
        }

        var tint: Color {
            switch self {
            case .ready: AppTheme.success
            case .pending: AppTheme.warning
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(state.tint)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CommercialNotesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("数据与隐私") {
                    Text("图像识别和语音转写优先在设备侧处理。若后续接入云端模型，需要补充隐私政策、数据保留周期和用户授权入口。")
                }

                Section("模型与授权") {
                    Text("当前 MobileNetV2 来自 Apple 官方 Core ML 模型库。生成式模型和自训练声音模型上线前应确认许可证、分发方式、模型体积和目标设备性能。")
                }

                Section("产品化建议") {
                    Text("建议增加订阅权益、用量限制、错误上报、模型版本号、离线模式说明和 App Store 隐私标签配置。")
                }
            }
            .navigationTitle("商用说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
