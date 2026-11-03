//
//  ChatMessage.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Pesan siap tampil. `id` = `message_id` (stabil di history dan SSE), `seq` = urutan percakapan.
struct ChatMessage: Identifiable, Equatable {
    let id: String
    let seq: Int
    let author: ChatAuthor
    /// Nil untuk payload non-teks yang belum punya renderer.
    let text: String?
    let status: ChatMessageStatus
    /// Nil bila `created_at` kosong atau bukan ISO 8601; pesan ikut hari pesan sebelumnya.
    let createdAt: Date?
    /// Penanda pertanyaan dari aplikasi ini; dicocokkan dengan pertanyaan yang sedang ditunggu.
    let clientMessageID: String?

    /// Nil bila `seq` bukan angka desimal: pesan tanpa urutan tidak bisa digabung dengan aman.
    init?(wire: WireMessage) {
        guard let seq = Int(wire.seq) else { return nil }
        self.init(
            id: wire.messageId, seq: seq, author: wire.direction, text: wire.payload, status: wire.status,
            createdAt: wire.createdAt.flatMap(Date.init(wire:)), clientMessageID: wire.clientMsgId
        )
    }

    init(
        id: String, seq: Int, author: ChatAuthor, text: String?, status: ChatMessageStatus, createdAt: Date? = nil,
        clientMessageID: String? = nil
    ) {
        self.id = id
        self.seq = seq
        self.author = author
        self.text = text
        self.status = status
        self.createdAt = createdAt
        self.clientMessageID = clientMessageID
    }
}
