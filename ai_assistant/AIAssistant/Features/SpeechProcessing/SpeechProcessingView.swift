import SwiftUI

struct SpeechProcessingView: View {
    @StateObject private var processor = SpeechProcessor()

    var body: some View {
        VStack(spacing: AppTheme.largeSpacing) {
            ModelStatusView(
                title: "语音处理",
                message: processor.modelNote,
                tone: .info
            )

            VStack(spacing: 18) {
                Image(systemName: processor.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 76, weight: .light))
                    .foregroundStyle(processor.isRecording ? AppTheme.accent : AppTheme.secondary)
                    .symbolEffect(.pulse, isActive: processor.isRecording)
                    .accessibilityHidden(true)

                Text(processor.status)
                    .font(.headline)
                    .accessibilityLabel("语音处理状态：\(processor.status)")

                Button {
                    processor.toggleRecording()
                } label: {
                    Label(processor.isRecording ? "停止录音" : "开始录音",
                          systemImage: processor.isRecording ? "stop.fill" : "record.circle")
                        .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(processor.isRecording ? AppTheme.accent : AppTheme.primary)
            }
            .padding(20)
            .cardSurface()

            ScrollView {
                Text(processor.transcript.isEmpty ? "转写文本会显示在这里。" : processor.transcript)
                    .font(.body)
                    .foregroundStyle(processor.transcript.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
            }
            .frame(maxHeight: .infinity)
            .cardSurface()
        }
        .padding(AppTheme.spacing)
        .background(AppTheme.pageBackground)
        .navigationTitle("语音处理")
        .navigationBarTitleDisplayMode(.inline)
    }
}
