import Foundation

public struct StreamMetrics: Codable, Sendable {
    public let transportActive: Bool
    public let sourceFPS: Double
    public let decodedFPS: Double
    public let publishedFPS: Double
    public let sentFPS: Double
    public let backendDroppedFPS: Double
    public let frameAgeMs: Double
    public let websocketSendMs: Double
    public let decoderAcceptMs: Double
    public let presentationAckMs: Double
    public let megabitsPerSecond: Double

    private enum CodingKeys: String, CodingKey {
        case transportActive = "transport_active"
        case sourceFPS = "source_fps"
        case decodedFPS = "decoded_fps"
        case publishedFPS = "published_fps"
        case sentFPS = "sent_fps"
        case backendDroppedFPS = "backend_dropped_fps"
        case frameAgeMs = "frame_age_ms"
        case websocketSendMs = "websocket_send_ms"
        case decoderAcceptMs = "decoder_accept_ms"
        case presentationAckMs = "presentation_ack_ms"
        case megabitsPerSecond = "megabits_per_second"
    }
}
