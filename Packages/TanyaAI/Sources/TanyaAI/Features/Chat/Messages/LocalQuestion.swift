//
//  LocalQuestion.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import Foundation

/// Pertanyaan yang langsung tampil saat dikirim, sebelum salinannya datang dari stream. Salinan stream
/// (dicocokkan lewat `client_msg_id` atau seq ack) menggantikannya; yang gagal dikirim tetap tampil abu-abu
/// tanpa retry selama halaman hidup, karena gateway tidak pernah menyimpannya.
struct LocalQuestion: Identifiable, Equatable {
    /// `client_msg_id` yang dikirim ke gateway.
    let id: String
    let text: String
    /// `seq` pesan terakhir saat dikirim; posisi bubble di daftar tetap setelah pesan itu.
    let afterSeq: Int?
    /// Waktu perangkat saat dikirim; menentukan chip tanggal selama salinan dari stream belum datang.
    var sentAt = Date()
    /// Seq dari ack kirim; nil sebelum ack atau bila gateway menolak.
    var seq: Int?
    var isFailed = false

    /// True bila salinannya dari stream atau history sudah ada di `messages` (urut `seq` naik).
    func isDelivered(in messages: [ChatMessage]) -> Bool {
        let floor = afterSeq ?? .min
        return messages.reversed().prefix { $0.seq > floor }.contains { message in
            message.author == .user && (message.clientMessageID == id || (seq != nil && message.seq == seq))
        }
    }
}
