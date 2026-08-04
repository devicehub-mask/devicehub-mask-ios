import AVFoundation
import Foundation

@MainActor
final class DeviceHubAudioPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private var started = false
    private var scheduledSeconds = 0.0

    init() {
        engine.attach(player)
    }

    func enqueue(_ packet: AudioPacket) -> String? {
        guard packet.sampleRate > 0, (1...2).contains(packet.channels) else {
            return "The audio packet format is unsupported."
        }
        let bytesPerFrame = MemoryLayout<Int16>.size * packet.channels
        let frameCount = packet.data.count / bytesPerFrame
        guard frameCount > 0 else { return nil }

        let nextFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Double(packet.sampleRate),
            channels: AVAudioChannelCount(packet.channels),
            interleaved: false
        )
        guard let nextFormat, let buffer = AVAudioPCMBuffer(
            pcmFormat: nextFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            return "Unable to create the native audio buffer."
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        packet.data.withUnsafeBytes { rawBuffer in
            let bytes = rawBuffer.bindMemory(to: UInt8.self)
            guard let channelData = buffer.floatChannelData else { return }
            for frame in 0..<frameCount {
                for channel in 0..<packet.channels {
                    let offset = (frame * packet.channels + channel) * 2
                    let bits = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
                    let sample = Int16(bitPattern: bits)
                    channelData[channel][frame] = sample < 0
                        ? Float(sample) / 32_768
                        : Float(sample) / 32_767
                }
            }
        }

        do {
            if format?.sampleRate != nextFormat.sampleRate || format?.channelCount != nextFormat.channelCount {
                player.stop()
                engine.disconnectNodeOutput(player)
                engine.connect(player, to: engine.mainMixerNode, format: nextFormat)
                format = nextFormat
                scheduledSeconds = 0
            } else if format == nil {
                engine.connect(player, to: engine.mainMixerNode, format: nextFormat)
                format = nextFormat
            }

            if !started {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .moviePlayback)
                try audioSession.setActive(true)
                try engine.start()
                started = true
            }
        } catch {
            return error.localizedDescription
        }

        let duration = Double(frameCount) / Double(packet.sampleRate)
        if scheduledSeconds > 0.25 {
            player.stop()
            scheduledSeconds = 0
        }
        scheduledSeconds += duration
        player.scheduleBuffer(buffer, completionCallbackType: .dataConsumed) { [weak self] _ in
            Task { @MainActor in
                self?.scheduledSeconds = max(0, (self?.scheduledSeconds ?? 0) - duration)
            }
        }
        if !player.isPlaying {
            player.play()
        }
        return nil
    }

    func reset() {
        player.stop()
        player.reset()
        engine.stop()
        started = false
        format = nil
        scheduledSeconds = 0
    }
}
