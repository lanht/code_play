import SwiftUI

enum FeatureDestination: String, CaseIterable, Identifiable {
    case imageRecognition
    case speechProcessing
    case imageGeneration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .imageRecognition: "图像识别"
        case .speechProcessing: "语音处理"
        case .imageGeneration: "图像生成"
        }
    }

    var subtitle: String {
        switch self {
        case .imageRecognition: "内置 MobileNetV2，支持中文结果展示"
        case .speechProcessing: "系统语音转写，可扩展声音分类"
        case .imageGeneration: "生成式模型入口，支持后续接入扩散模型"
        }
    }

    var badge: String {
        switch self {
        case .imageRecognition: "已可用"
        case .speechProcessing: "系统能力"
        case .imageGeneration: "可扩展"
        }
    }

    var systemImage: String {
        switch self {
        case .imageRecognition: "camera.viewfinder"
        case .speechProcessing: "waveform"
        case .imageGeneration: "sparkles.rectangle.stack"
        }
    }

    var tint: Color {
        switch self {
        case .imageRecognition: AppTheme.primary
        case .speechProcessing: AppTheme.secondary
        case .imageGeneration: AppTheme.accent
        }
    }
}
