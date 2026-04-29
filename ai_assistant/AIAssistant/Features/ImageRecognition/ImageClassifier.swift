import CoreML
import SwiftUI
@preconcurrency import Vision

@MainActor
final class ImageClassifier: ObservableObject {
    @Published var state: ClassificationState = .idle

    func classify(_ image: UIImage) async {
        guard let cgImage = image.cgImage else {
            state = .failed("无法读取图片像素。")
            return
        }

        state = .loading

        do {
            let results = try await Self.performClassification(cgImage: cgImage)
            state = .ready(results)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private nonisolated static func performClassification(cgImage: CGImage) async throws -> [ClassificationResult] {
        let model = try loadVisionModel()

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNClassificationObservation]) ?? []
                let mapped = observations.prefix(5).map {
                    ClassificationResult(
                        label: $0.identifier,
                        localizedLabel: ImageNetLabelLocalizer.localizedLabel(for: $0.identifier),
                        confidence: Double($0.confidence)
                    )
                }
                continuation.resume(returning: mapped)
            }
            request.imageCropAndScaleOption = .centerCrop

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: cgImage).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated static func loadVisionModel() throws -> VNCoreMLModel {
        let names = ["ImageClassifier", "MobileNetV2", "Resnet50", "SqueezeNet"]

        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc"),
               let model = try? MLModel(contentsOf: url),
               let visionModel = try? VNCoreMLModel(for: model) {
                return visionModel
            }
        }

        throw CoreMLFeatureError.missingModel(
            "未找到图像识别模型。请把 ImageClassifier.mlmodel 或 MobileNetV2.mlmodel 加入 App target。"
        )
    }
}

struct ClassificationResult: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let localizedLabel: String
    let confidence: Double
}

enum ClassificationState: Equatable {
    case idle
    case loading
    case ready([ClassificationResult])
    case failed(String)
}

enum CoreMLFeatureError: LocalizedError {
    case missingModel(String)

    var errorDescription: String? {
        switch self {
        case .missingModel(let message): message
        }
    }
}
