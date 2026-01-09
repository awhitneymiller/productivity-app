import Foundation
import AVFoundation
import FluidAudio

@MainActor
final class VoiceTranscriber: ObservableObject {
    @Published var isRecording = false
    @Published var transcript: String = ""
    @Published var status: String = "Idle"

    private let engine = AVAudioEngine()
    private var capturedPCM: [AVAudioPCMBuffer] = []

    private var asrManager: AsrManager?
    private var isAsrReady = false

    // MARK: - Public

    func toggle() {
        if isRecording {
            stopAndTranscribe()
        } else {
            startRecording()
        }
    }

    // MARK: - Setup ASR once

    private func ensureAsrReady() async throws {
        if isAsrReady { return }

        status = "Loading ASR model…"

        // Downloads + loads Parakeet models (v3 multilingual; v2 english-only higher recall)
        let models = try await AsrModels.downloadAndLoad(version: .v3)  // .v2 if you want English-only :contentReference[oaicite:3]{index=3}

        let manager = AsrManager(config: .default)
        try await manager.initialize(models: models) // :contentReference[oaicite:4]{index=4}

        self.asrManager = manager
        self.isAsrReady = true
        status = "ASR ready"
    }

    // MARK: - Recording

    private func startRecording() {
        transcript = ""
        status = "Recording…"
        capturedPCM.removeAll()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: [])
        } catch {
            status = "Audio session error: \(error.localizedDescription)"
            return
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            // Copy buffer because the engine reuses memory
            if let copy = buffer.copy() as? AVAudioPCMBuffer {
                self.capturedPCM.append(copy)
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isRecording = true
        } catch {
            status = "Engine start error: \(error.localizedDescription)"
        }
    }

    private func stopAndTranscribe() {
        status = "Stopping…"
        isRecording = false

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        Task {
            await transcribeCapturedAudio()
        }
    }

    // MARK: - Transcription

    private func transcribeCapturedAudio() async {
        do {
            try await ensureAsrReady()
            guard let asrManager else { return }

            status = "Converting audio…"

            // Merge captured buffers into one, then resample to 16k mono as models expect.
            guard let merged = merge(buffers: capturedPCM) else {
                status = "No audio captured"
                return
            }

            let samples16k = try await convertTo16kMonoSamples(buffer: merged)

            status = "Transcribing…"
            let result = try await asrManager.transcribe(samples16k) // :contentReference[oaicite:5]{index=5}
            transcript = result.text
            status = "Done"
        } catch {
            status = "Transcription error: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func merge(buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer? {
        guard let first = buffers.first else { return nil }
        let format = first.format

        let totalFrames = buffers.reduce(0) { $0 + Int($1.frameLength) }
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames)) else { return nil }

        output.frameLength = 0

        for b in buffers {
            let dstStart = Int(output.frameLength)
            let frames = Int(b.frameLength)

            guard
                let dst = output.floatChannelData,
                let src = b.floatChannelData
            else { continue }

            let channels = Int(format.channelCount)
            for c in 0..<channels {
                memcpy(dst[c] + dstStart, src[c], frames * MemoryLayout<Float>.size)
            }

            output.frameLength += b.frameLength
        }

        return output
    }

    private func convertTo16kMonoSamples(buffer: AVAudioPCMBuffer) async throws -> [Float] {
        // FluidAudio includes helpers via AudioConverter in examples/docs; this is a simple AVAudioConverter path.
        // Output: 16kHz mono float32 PCM samples.
        let inputFormat = buffer.format

        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                              sampleRate: 16_000,
                                              channels: 1,
                                              interleaved: false) else {
            throw NSError(domain: "VoiceTranscriber", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output format"])
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw NSError(domain: "VoiceTranscriber", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
        }

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024

        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outCapacity) else {
            throw NSError(domain: "VoiceTranscriber", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)
        if let error { throw error }

        guard let ch0 = outBuffer.floatChannelData?[0] else {
            throw NSError(domain: "VoiceTranscriber", code: -4, userInfo: [NSLocalizedDescriptionKey: "No channel data"])
        }

        let frameCount = Int(outBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: ch0, count: frameCount))
    }
}
