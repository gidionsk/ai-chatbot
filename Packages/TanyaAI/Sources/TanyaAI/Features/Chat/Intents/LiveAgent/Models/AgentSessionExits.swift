//
//  AgentSessionExits.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Posisi akhir sesi agen yang diterima selama halaman terbuka. History tidak membawa event `state`, jadi posisi ini
/// hanya ada dari stream, termasuk replay setelah history dimuat; kartu selesai memakainya sebelum menebak dari pesan.
struct AgentSessionExits: Equatable {
    /// `seq` event `state` yang keluar dari antre atau agen.
    private(set) var seqs: Set<Int> = []
    /// `leave-agent` sudah menjawab `left:true` tetapi event `state`-nya belum tiba: `seq` terakhir yang diketahui saat
    /// itu. Pertanyaan ke bot yang dikirim sesudahnya tetap di bawah kartu selesai.
    var pendingSeq: Int?

    /// Posisi yang dipakai kartu selesai, urut naik.
    var positions: [Int] { (Array(seqs) + [pendingSeq].compactMap { $0 }).sorted() }

    /// Event `state` dari stream. Keluar dari antre atau agen dicatat posisinya; masuk lagi ke antre atau agen berarti
    /// sesi baru, jadi posisi tunggu dari `leave-agent` sebelumnya tidak berlaku.
    mutating func record(_ change: ConversationStateChange) {
        guard let seq = change.agentExitSeq else {
            pendingSeq = change.next.isLiveAgent ? nil : pendingSeq
            return
        }
        seqs.insert(seq)
        pendingSeq = nil
    }
}
