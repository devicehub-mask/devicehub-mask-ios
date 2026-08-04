import XCTest
@testable import DeviceHubCore

final class MediaPacketParserTests: XCTestCase {
    func testParsesVideoHeaderAndPayload() throws {
        var bytes = Data("DHV2".utf8)
        bytes.append(contentsOf: [1, 0, 0, 0])
        bytes.append(bigEndian: 42 as UInt64)
        bytes.append(bigEndian: 7 as UInt64)
        bytes.append(bigEndian: 3 as UInt64)
        bytes.append(bigEndian: 1170 as UInt16)
        bytes.append(bigEndian: 2532 as UInt16)
        bytes.append(contentsOf: [0, 0, 1, 0x26, 1, 2, 3])

        guard case .video(let packet) = try MediaPacketParser.parse(bytes) else {
            return XCTFail("Expected a video packet")
        }
        XCTAssertTrue(packet.keyframe)
        XCTAssertEqual(packet.timestamp, 42)
        XCTAssertEqual(packet.sequence, 7)
        XCTAssertEqual(packet.generation, 3)
        XCTAssertEqual(packet.width, 1170)
        XCTAssertEqual(packet.height, 2532)
        XCTAssertEqual(packet.data, Data([0, 0, 1, 0x26, 1, 2, 3]))
    }

    func testParsesAudioHeaderAndPayload() throws {
        var bytes = Data("DHA1".utf8)
        bytes.append(bigEndian: 48_000 as UInt32)
        bytes.append(bigEndian: 2 as UInt16)
        bytes.append(contentsOf: [0, 0])
        bytes.append(contentsOf: [1, 2, 3, 4, 5, 6, 7, 8])

        guard case .audio(let packet) = try MediaPacketParser.parse(bytes) else {
            return XCTFail("Expected an audio packet")
        }
        XCTAssertEqual(packet.sampleRate, 48_000)
        XCTAssertEqual(packet.channels, 2)
        XCTAssertEqual(packet.data, Data([1, 2, 3, 4, 5, 6, 7, 8]))
    }

    func testRejectsInvalidAudioPayload() {
        var bytes = Data("DHA1".utf8)
        bytes.append(bigEndian: 48_000 as UInt32)
        bytes.append(bigEndian: 2 as UInt16)
        bytes.append(contentsOf: [0, 0, 1])

        XCTAssertThrowsError(try MediaPacketParser.parse(bytes))
    }
}

private extension Data {
    mutating func append(bigEndian value: UInt16) {
        append(UInt8(value >> 8))
        append(UInt8(value & 0xFF))
    }

    mutating func append(bigEndian value: UInt32) {
        append(UInt8(value >> 24))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func append(bigEndian value: UInt64) {
        for shift in stride(from: 56, through: 0, by: -8) {
            append(UInt8((value >> UInt64(shift)) & 0xFF))
        }
    }
}
