//
//  ChatRow.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import Foundation

/// Satu baris daftar pesan: pesan dari gateway atau pertanyaan yang belum dikonfirmasi stream.
enum ChatRow: Identifiable, Equatable {
    case message(ChatMessage)
    case local(LocalQuestion)

    var id: String {
        switch self {
        case .message(let message):
            return message.id
        case .local(let question):
            return question.id
        }
    }

    /// Tanggal untuk chip per hari: `created_at` gateway atau waktu kirim pertanyaan lokal.
    var date: Date? {
        switch self {
        case .message(let message):
            return message.createdAt
        case .local(let question):
            return question.sentAt
        }
    }

    /// Punya tampilan di daftar: teks dari nasabah, bot, atau agen, serta setiap pertanyaan lokal.
    var isVisible: Bool {
        switch self {
        case .message(let message):
            return message.text != nil && message.author != .unknown
        case .local:
            return true
        }
    }
}
