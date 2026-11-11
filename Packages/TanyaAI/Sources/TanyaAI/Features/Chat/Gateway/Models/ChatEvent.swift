//
//  ChatEvent.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Event SSE yang dipakai aplikasi. `typing` dari nasabah sendiri (perangkat lain) diabaikan.
enum ChatEvent: Equatable {
    /// Pesan lengkap (bukan delta), termasuk pesan nasabah sendiri dan tombstone `canceled`.
    case message(ChatMessage)
    /// Satu-satunya event pembuka kunci: jawaban selesai, gagal, atau dibatalkan. `seq` dari `id:` frame.
    case turnEnd(seq: Int?)
    /// State percakapan berpindah, mis. ke antrean atau agen manusia.
    case state(ConversationState)
    /// Notifikasi live agent yang menjadi kartu status.
    case notice(LiveAgentNotice)
    /// Agen sedang mengetik; indikator hilang sendiri setelah `lifetime` detik tanpa kabar baru.
    case agentTyping(isTyping: Bool, lifetime: TimeInterval)
    case ignored

    /// Frame yang gagal di-decode diabaikan agar satu pesan rusak tidak memutus stream.
    init(_ event: ServerSentEvent) {
        let data = Data(event.data.utf8)
        switch event.name {
        case ChatWire.Event.message:
            let wire = try? JSONDecoder.wire.decode(WireMessage.self, from: data)
            self = wire.flatMap(ChatMessage.init(wire:)).map(ChatEvent.message) ?? .ignored
        case ChatWire.Event.turnEnd:
            self = .turnEnd(seq: event.id.flatMap(Int.init))
        case ChatWire.Event.state:
            let wire = try? JSONDecoder.wire.decode(WireStateChange.self, from: data)
            self = wire.map { .state($0.nextState) } ?? .ignored
        case ChatWire.Event.system:
            self = Self.notice(from: data, seq: event.id.flatMap(Int.init)) ?? .ignored
        case ChatWire.Event.typing:
            self = Self.agentTyping(from: data) ?? .ignored
        default:
            self = .ignored
        }
    }
}

// MARK: - Helpers

private extension ChatEvent {
    /// Jenis yang bukan kartu (mis. `agent_joined`) atau frame tanpa `id:` tidak punya posisi di daftar.
    static func notice(from data: Data, seq: Int?) -> ChatEvent? {
        guard let seq, let wire = try? JSONDecoder.wire.decode(WireSystemNotice.self, from: data),
            let kind = LiveAgentNoticeKind(rawValue: wire.type)
        else { return nil }
        return .notice(LiveAgentNotice(kind: kind, seq: seq))
    }

    static func agentTyping(from data: Data) -> ChatEvent? {
        guard let wire = try? JSONDecoder.wire.decode(WireTyping.self, from: data), wire.direction == .agent else {
            return nil
        }
        return .agentTyping(isTyping: wire.isTyping, lifetime: wire.lifetimeSeconds ?? ChatWire.typingLifetime)
    }
}
