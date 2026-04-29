import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechProcessor: ObservableObject {
    @Published var transcript = ""
    @Published var status = "等待录音"
    @Published var isRecording = false
    @Published var modelNote = "可加入 SoundClassifier.mlmodel 后扩展声音分类。"

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))

    func toggleRecording() {
        isRecording ? stopRecording() : requestAndStart()
    }

    private func requestAndStart() {
        Task {
            let speechGranted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }

            let micGranted = await AVAudioApplication.requestRecordPermission()

            guard speechGranted, micGranted else {
                status = "需要麦克风和语音识别权限"
                return
            }

            do {
                try startRecording()
            } catch {
                status = error.localizedDescription
            }
        }
    }

    private func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isRecording = true
        status = "正在聆听"
        transcript = ""

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.status = result.isFinal ? "转写完成" : "正在转写"
                }
                if error != nil {
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        status = transcript.isEmpty ? "录音已停止" : "转写完成"
    }
}
