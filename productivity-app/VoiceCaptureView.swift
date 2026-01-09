import SwiftUI

struct VoiceCaptureView: View {
    @StateObject private var transcriber = VoiceTranscriber()

    var body: some View {
        VStack(spacing: 16) {
            Text("Voice Input")
                .font(.title2).bold()

            Text(transcriber.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(transcriber.transcript.isEmpty ? "Say something like: “Meeting with Maya tomorrow at 3, remind me 30 minutes before, bring my charger.”" : transcriber.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button(action: { transcriber.toggle() }) {
                Text(transcriber.isRecording ? "Stop & Transcribe" : "Record")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
