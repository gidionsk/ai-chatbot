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
    /// `leave-agent` sudah menjawab `left:true` tetapi event `state`-nya belum tiba: sesi berakhir di ujung daftar.
    var isPending = false

    /// Posisi yang dipakai kartu selesai; `Int.max` = ujung daftar selama event `state` ditunggu.
    var positions: [Int] { seqs.sorted() + (isPending ? [.max] : []) }

    /// Event `state` dari stream. Keluar dari antre atau agen dicatat posisinya; masuk lagi ke antre atau agen berarti
    /// sesi baru, jadi penanda tunggu dari `leave-agent` sebelumnya tidak berlaku.
    mutating func record(_ change: ConversationStateChange) {
        guard let seq = change.agentExitSeq else {
            isPending = isPending && !change.next.isLiveAgent
            return
        }
        seqs.insert(seq)
        isPending = false
    }
}
