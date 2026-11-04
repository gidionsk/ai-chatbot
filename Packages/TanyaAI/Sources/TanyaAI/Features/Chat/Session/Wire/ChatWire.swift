//
//  ChatWire.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// Metadata teknis contract chat-gateway 1.0.1: prefix baris SSE, nama event, dan batas paging.
/// Bukan copy untuk pengguna.
enum ChatWire {
    static let idField = "id:"
    static let eventField = "event:"
    static let dataField = "data:"
    /// Baris komentar SSE, misalnya `: connected` dan `: keepalive`.
    static let commentPrefix = ":"
    /// Satu spasi setelah titik dua bukan bagian dari nilai field (aturan SSE).
    static let fieldValueSpace = " "
    /// Jumlah pesan per halaman history (contract: 1...100).
    static let historyPageSize = 30

    enum Event {
        /// Nama default event SSE bila baris `event:` tidak ada.
        static let message = "message"
        static let turnEnd = "turn_end"
        /// Ephemeral (tanpa baris outbox): `id:`-nya bukan posisi replay.
        static let typing = "typing"
    }
}
