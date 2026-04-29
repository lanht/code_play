import CoreImage
import CoreImage.CIFilterBuiltins
import CoreML
import SwiftUI

@MainActor
final class ImageGenerator: ObservableObject {
    @Published var prompt = "未来感的 Core ML 实验室，柔和光线，iOS 应用图标风格"
    @Published var image: UIImage?
    @Published var status = "等待生成"
    @Published var isGenerating = false

    func generate() async {
        isGenerating = true
        status = "正在检查生成模型"
        defer { isGenerating = false }

        if Bundle.main.url(forResource: "ImageGenerator", withExtension: "mlmodelc") != nil {
            status = "已发现 ImageGenerator.mlmodelc，请在 ImageGenerator.swift 中按模型输入输出补全推理。"
            image = Self.placeholderImage(seed: prompt)
            return
        }

        status = "未找到 ImageGenerator.mlmodel，已生成本地占位预览。"
        image = Self.placeholderImage(seed: prompt)
    }

    private nonisolated static func placeholderImage(seed: String) -> UIImage {
        let size = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)
        let hash = abs(seed.hashValue)

        return renderer.image { context in
            let cgContext = context.cgContext
            let colors = [
                UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1).cgColor,
                UIColor(red: 0.93, green: 0.28, blue: 0.60, alpha: 1).cgColor,
                UIColor(red: 0.13, green: 0.18, blue: 0.36, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.52, 1])!
            cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            for index in 0..<16 {
                let x = CGFloat((hash + index * 97) % 820) + 60
                let y = CGFloat((hash / 3 + index * 131) % 820) + 60
                let side = CGFloat(72 + (hash + index * 23) % 160)
                let alpha = CGFloat(0.10 + Double((index % 5)) * 0.035)
                cgContext.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                cgContext.fillEllipse(in: CGRect(x: x, y: y, width: side, height: side))
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 44, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let text = "AIAssistant Preview"
            text.draw(in: CGRect(x: 80, y: 466, width: 864, height: 80), withAttributes: attributes)
        }
    }
}
