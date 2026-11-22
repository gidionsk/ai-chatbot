//
//  ChatSheet.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Bottom sheet yang sedang tampil di halaman chat; satu pemasangan `.bottomSheet(item:)` untuk semua jenisnya. Nilai
/// lain membangun sheet baru seutuhnya.
enum ChatSheet: Hashable {
    /// Pilihan Galeri / File untuk sesi agen yang melayani saat tombol `+` diketuk. `isFormatRejected` = dibuka lagi
    /// tepat setelah foto galeri ditolak, dengan pesan format.
    case attachment(AgentSessionKey, isFormatRejected: Bool)
    /// Konfirmasi End Session untuk antrean atau sesi yang tampil saat tombol diketuk.
    case leaveAgent(AgentSessionKey)

    case referenceLetterChoices(messageID: String, field: ReferenceLetterFieldID)
    case referenceLetterPIN(messageID: String)

    var referenceLetterMessageID: String? {
        switch self {
        case .attachment, .leaveAgent:
            return nil
        case .referenceLetterChoices(let messageID, _), .referenceLetterPIN(let messageID):
            return messageID
        }
    }
}
