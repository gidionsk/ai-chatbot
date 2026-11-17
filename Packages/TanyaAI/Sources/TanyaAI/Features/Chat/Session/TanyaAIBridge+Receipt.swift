//
//  TanyaAIBridge+Receipt.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// Menandai pesan intent selesai setelah transaksinya berhasil di host (contract §2.3a). Pesan di daftar langsung
    /// diperbarui tanpa menunggu gateway mengirim ulang frame-nya: kiriman ulang itu tidak ada untuk nilai yang sama
    /// (`deduplicated:true`) dan terlewat bila stream putus setelah `Last-Event-ID` melewati `seq` pesan.
    /// 401 mengakhiri sesi seperti jalur lain. Error lain dilempar ke pemanggil tanpa menutup percakapan, karena
    /// 404/409 di sini menyangkut pesannya, bukan percakapannya.
    func attachSuccessID(_ successID: String, toMessageID messageID: String) async throws {
        do {
            _ = try await transport.attachSuccessID(messageID: messageID, successID: successID)
        } catch {
            expireSessionIfUnauthorized(error)
            throw error
        }
        // Pesan sudah tidak ada bila init memberi percakapan lain selama request berjalan.
        guard let message = messages.first(where: { $0.id == messageID }) else { return }
        apply(.message(message.receipted(successID: successID)))
    }
}
