//
//  ChatEvent.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Event SSE yang dipakai UI. `system`, `typing`, dan `state` belum punya tampilan sehingga diabaikan;
/// status percakapan ditutup dibaca dari `/chat/init` saat menyambung ulang.
enum ChatEvent: Equatable {
    /// Pesan lengkap (bukan delta), termasuk pesan nasabah sendiri dan tombstone `canceled`.
    case message(ChatMessage)
    /// Satu-satunya event pembuka kunci: jawaban selesai, gagal, atau dibatalkan. `seq` dari `id:` frame.
    case turnEnd(seq: Int?)
    case ignored

    /// Frame yang gagal di-decode diabaikan agar satu pesan rusak tidak memutus stream.
    init(_ event: ServerSentEvent) {
        switch event.name {
        case ChatWire.Event.message:
            let wire = try? JSONDecoder.wire.decode(WireMessage.self, from: Data(event.data.utf8))
            self = wire.flatMap(ChatMessage.init(wire:)).map(ChatEvent.message) ?? .ignored
        case ChatWire.Event.turnEnd:
            self = .turnEnd(seq: event.id.flatMap(Int.init))
        default:
            self = .ignored
        }
    }
}
