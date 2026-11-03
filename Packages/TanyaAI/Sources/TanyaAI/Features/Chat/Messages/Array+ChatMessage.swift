//
//  Array+ChatMessage.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

extension Array where Element == ChatMessage {
    /// `seq` terbesar di daftar; dikirim sebagai `Last-Event-ID` dan batas mengejar history.
    var latestSeq: Int? {
        map(\.seq).max()
    }

    /// Gabung tanpa menumpuk: pesan dengan `id` sama diganti versi yang datang (mis. tombstone `canceled`),
    /// pesan baru ditambahkan, hasil urut `seq` naik walau history datang terbaru dulu.
    func merging(_ incoming: [ChatMessage]) -> [ChatMessage] {
        // Jalur cepat SSE: satu pesan baru di ujung, tanpa mengurutkan ulang seluruh daftar.
        if let message = incoming.first, incoming.dropFirst().isEmpty, message.seq > (latestSeq ?? .min),
            !contains(where: { $0.id == message.id })
        {
            return self + incoming
        }
        var byID = Dictionary(map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        incoming.forEach { byID[$0.id] = $0 }
        return byID.values.sorted { $0.seq < $1.seq }
    }

    /// Daftar tampil: pertanyaan lokal disisipkan tepat setelah pesan terakhir saat ia dikirim, jadi bubble gagal
    /// tetap di tempatnya walau pertanyaan dan jawaban berikutnya datang. `locals` urut waktu kirim.
    func rows(with locals: [LocalQuestion]) -> [ChatRow] {
        var pending = locals[...]
        var rows: [ChatRow] = []
        rows.reserveCapacity(count + locals.count)
        for message in self {
            while let local = pending.first, (local.afterSeq ?? .min) < message.seq {
                rows.append(.local(local))
                pending = pending.dropFirst()
            }
            rows.append(.message(message))
        }
        return rows + pending.map(ChatRow.local)
    }
}
