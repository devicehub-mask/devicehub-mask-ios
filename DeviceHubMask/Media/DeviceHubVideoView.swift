import AVFoundation
import Foundation
import UIKit

@MainActor
final class DeviceHubVideoView: UIView {
    private let displayLayer = AVSampleBufferDisplayLayer()
    private var formatDescription: CMVideoFormatDescription?
    private var vps: Data?
    private var sps: Data?
    private var pps: Data?
    private var streamGeneration: UInt64?
    private var orientation = Orientation.portrait
    private var contentModeName = "fit"

    private var sampleBufferRenderer: AVSampleBufferVideoRenderer {
        displayLayer.sampleBufferRenderer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.addSublayer(displayLayer)
        displayLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        layer.addSublayer(displayLayer)
        displayLayer.videoGravity = .resizeAspect
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let isLandscape = orientation.isLandscape
        let layerSize = isLandscape
            ? CGSize(width: bounds.height, height: bounds.width)
            : bounds.size
        displayLayer.bounds = CGRect(origin: .zero, size: layerSize)
        displayLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        displayLayer.setAffineTransform(orientationTransform)
    }

    func update(orientation: Orientation, contentMode: DeviceHubContentMode) {
        self.orientation = orientation
        contentModeName = contentMode == .fill ? "fill" : "fit"
        displayLayer.videoGravity = contentModeName == "fill" ? .resizeAspectFill : .resizeAspect
        setNeedsLayout()
    }

    @discardableResult
    func enqueue(_ packet: VideoPacket) -> Bool {
        if streamGeneration != packet.generation {
            streamGeneration = packet.generation
            resetDecoder()
        }
        guard let sample = makeSample(from: packet.data, timestamp: packet.timestamp),
              sampleBufferRenderer.isReadyForMoreMediaData || packet.keyframe else {
            return false
        }
        if packet.keyframe, sampleBufferRenderer.status == .failed {
            sampleBufferRenderer.flush()
        }
        sampleBufferRenderer.enqueue(sample)
        return true
    }

    func reset() {
        resetDecoder()
        sampleBufferRenderer.flush()
    }

    private func resetDecoder() {
        formatDescription = nil
        vps = nil
        sps = nil
        pps = nil
    }

    private func makeSample(from annexB: Data, timestamp: UInt64) -> CMSampleBuffer? {
        let nalUnits = Self.nalUnits(in: annexB)
        guard !nalUnits.isEmpty else { return nil }

        var parameterSetsChanged = false
        for nal in nalUnits {
            guard let first = nal.first else { continue }
            switch (first >> 1) & 0x3F {
            case 32:
                parameterSetsChanged = parameterSetsChanged || vps != nal
                vps = nal
            case 33:
                parameterSetsChanged = parameterSetsChanged || sps != nal
                sps = nal
            case 34:
                parameterSetsChanged = parameterSetsChanged || pps != nal
                pps = nal
            default:
                break
            }
        }
        if parameterSetsChanged {
            formatDescription = nil
        }
        if formatDescription == nil, let vps, let sps, let pps {
            formatDescription = makeFormatDescription(vps: vps, sps: sps, pps: pps)
        }
        guard let formatDescription else { return nil }

        var lengthPrefixed = Data()
        for nal in nalUnits {
            guard let first = nal.first else { continue }
            let type = (first >> 1) & 0x3F
            if type == 32 || type == 33 || type == 34 || type == 35 { continue }
            var length = UInt32(nal.count).bigEndian
            withUnsafeBytes(of: &length) { lengthPrefixed.append(contentsOf: $0) }
            lengthPrefixed.append(nal)
        }
        guard !lengthPrefixed.isEmpty else { return nil }

        var blockBuffer: CMBlockBuffer?
        let blockStatus = lengthPrefixed.withUnsafeBytes { bytes -> OSStatus in
            guard let baseAddress = bytes.baseAddress else { return -1 }
            var status = CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: lengthPrefixed.count,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: lengthPrefixed.count,
                flags: 0,
                blockBufferOut: &blockBuffer
            )
            guard status == kCMBlockBufferNoErr, let blockBuffer else { return status }
            status = CMBlockBufferReplaceDataBytes(
                with: baseAddress,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: lengthPrefixed.count
            )
            return status
        }
        guard blockStatus == kCMBlockBufferNoErr, let blockBuffer else { return nil }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTime(
                value: CMTimeValue(min(timestamp, UInt64(Int64.max))),
                timescale: 1_000_000_000
            ),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let sampleStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 1,
            sampleSizeArray: [lengthPrefixed.count],
            sampleBufferOut: &sampleBuffer
        )
        guard sampleStatus == noErr else { return nil }
        return sampleBuffer
    }

    private func makeFormatDescription(vps: Data, sps: Data, pps: Data) -> CMVideoFormatDescription? {
        var description: CMVideoFormatDescription?
        let status = vps.withUnsafeBytes { vpsBytes in
            sps.withUnsafeBytes { spsBytes in
                pps.withUnsafeBytes { ppsBytes in
                    guard let vpsBase = vpsBytes.bindMemory(to: UInt8.self).baseAddress,
                          let spsBase = spsBytes.bindMemory(to: UInt8.self).baseAddress,
                          let ppsBase = ppsBytes.bindMemory(to: UInt8.self).baseAddress else {
                        return OSStatus(-1)
                    }
                    var pointers = [vpsBase, spsBase, ppsBase]
                    var sizes = [vps.count, sps.count, pps.count]
                    return pointers.withUnsafeMutableBufferPointer { pointerBuffer in
                        sizes.withUnsafeMutableBufferPointer { sizeBuffer in
                            guard let pointerBase = pointerBuffer.baseAddress,
                                  let sizeBase = sizeBuffer.baseAddress else {
                                return OSStatus(-1)
                            }
                            return CMVideoFormatDescriptionCreateFromHEVCParameterSets(
                                allocator: kCFAllocatorDefault,
                                parameterSetCount: 3,
                                parameterSetPointers: pointerBase,
                                parameterSetSizes: sizeBase,
                                nalUnitHeaderLength: 4,
                                extensions: nil,
                                formatDescriptionOut: &description
                            )
                        }
                    }
                }
            }
        }
        return status == noErr ? description : nil
    }

    private var orientationTransform: CGAffineTransform {
        switch orientation {
        case .landscapeRight:
            CGAffineTransform(rotationAngle: .pi / 2)
        case .landscapeLeft:
            CGAffineTransform(rotationAngle: -.pi / 2)
        case .portraitUpsideDown:
            CGAffineTransform(rotationAngle: .pi)
        case .portrait:
            .identity
        }
    }

    private static func nalUnits(in data: Data) -> [Data] {
        let bytes = [UInt8](data)
        var starts: [(offset: Int, length: Int)] = []
        var index = 0
        while index + 3 < bytes.count {
            if bytes[index] == 0, bytes[index + 1] == 0, bytes[index + 2] == 1 {
                starts.append((index, 3))
                index += 3
                continue
            }
            if index + 4 < bytes.count,
               bytes[index] == 0,
               bytes[index + 1] == 0,
               bytes[index + 2] == 0,
               bytes[index + 3] == 1 {
                starts.append((index, 4))
                index += 4
                continue
            }
            index += 1
        }
        return starts.enumerated().compactMap { position, start in
            let payloadStart = start.offset + start.length
            let payloadEnd = position + 1 < starts.count ? starts[position + 1].offset : bytes.count
            guard payloadEnd > payloadStart else { return nil }
            return Data(bytes[payloadStart..<payloadEnd])
        }
    }
}
