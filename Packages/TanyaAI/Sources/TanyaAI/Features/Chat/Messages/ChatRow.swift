//
//  ChatRow.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

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

    /// Pertanyaan nasabah: pesan gateway dari nasabah atau pertanyaan lokal.
    var isQuestion: Bool {
        switch self {
        case .message(let message):
            return message.author == .customer
        case .local:
            return true
        }
    }
}
