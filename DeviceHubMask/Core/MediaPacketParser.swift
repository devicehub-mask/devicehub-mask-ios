import Foundation

public enum MediaPacketParser {
    public static func parse(_ data: Data) throws -> MediaPacket? {
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else { return nil }

        if Array(bytes.prefix(4)) == Array("DHV2".utf8) {
            return try parseVideo(bytes, data: data)
        }
        if Array(bytes.prefix(4)) == Array("DHA1".utf8) {
            return try parseAudio(bytes, data: data)
        }
        return nil
    }

    private static func parseVideo(_ bytes: [UInt8], data: Data) throws -> MediaPacket {
        guard bytes.count >= 36 else {
            throw DeviceHubError.invalidMediaPacket("video header is truncated")
        }
        let width = Int(readUInt16(bytes, at: 32))
        let height = Int(readUInt16(bytes, at: 34))
        guard width > 0, height > 0 else {
            throw DeviceHubError.invalidMediaPacket("video dimensions are invalid")
        }
        return .video(VideoPacket(
            keyframe: bytes[4] == 1,
            timestamp: readUInt64(bytes, at: 8),
            sequence: readUInt64(bytes, at: 16),
            generation: readUInt64(bytes, at: 24),
            width: width,
            height: height,
            data: data.dropFirst(36)
        ))
    }

    private static func parseAudio(_ bytes: [UInt8], data: Data) throws -> MediaPacket {
        guard bytes.count >= 12 else {
            throw DeviceHubError.invalidMediaPacket("audio header is truncated")
        }
        let sampleRate = Int(readUInt32(bytes, at: 4))
        let channels = Int(readUInt16(bytes, at: 8))
        let payloadBytes = bytes.count - 12
        guard (8_000...192_000).contains(sampleRate) else {
            throw DeviceHubError.invalidMediaPacket("audio sample rate is invalid")
        }
        guard (1...8).contains(channels), payloadBytes > 0, payloadBytes.isMultiple(of: channels * 2) else {
            throw DeviceHubError.invalidMediaPacket("audio PCM payload is invalid")
        }
        return .audio(AudioPacket(
            sampleRate: sampleRate,
            channels: channels,
            data: data.dropFirst(12)
        ))
    }

    private static func readUInt16(_ bytes: [UInt8], at offset: Int) -> UInt16 {
        UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    private static func readUInt32(_ bytes: [UInt8], at offset: Int) -> UInt32 {
        UInt32(bytes[offset]) << 24
            | UInt32(bytes[offset + 1]) << 16
            | UInt32(bytes[offset + 2]) << 8
            | UInt32(bytes[offset + 3])
    }

    private static func readUInt64(_ bytes: [UInt8], at offset: Int) -> UInt64 {
        var value = UInt64.zero
        for index in 0..<8 {
            value = (value << 8) | UInt64(bytes[offset + index])
        }
        return value
    }
}
