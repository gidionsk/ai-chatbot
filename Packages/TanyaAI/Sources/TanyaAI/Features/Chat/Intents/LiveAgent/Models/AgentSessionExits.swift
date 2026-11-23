//
//  AgentSessionExits.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Batas sesi agen dari event `state` dan `leave-agent` yang diterima selama halaman terbuka. History tidak membawa
/// event `state`, jadi batas ini hanya ada dari stream, termasuk replay setelah history dimuat; kartu selesai
/// memakainya sebelum menebak dari pesan. Semua penanda disimpan apa adanya: `AgentSessionEndScan` yang menentukan
/// sesi mana yang ditutupnya, karena hanya scan yang membaca pesan di antaranya.
struct AgentSessionExits: Equatable {
    private var recorded: Set<AgentSessionMark> = []

    /// Penanda untuk kartu selesai, urut naik.
    var marks: [AgentSessionMark] { recorded.sorted() }

    /// Keluar dari antre atau agen = posisi akhir sesi. Masuk ke antre atau agen dari state yang diketahui di luar
    /// keduanya = awal antrean baru. Antre ke dilayani agen masih sesi yang sama, dan state asal yang tidak dikenal
    /// tidak dianggap antrean baru.
    mutating func record(_ change: ConversationStateChange) {
        guard let seq = change.seq else { return }
        guard change.agentExitSeq == nil else {
            recorded.insert(.exit(seq: seq, isServed: change.previous == .agentActive))
            return
        }
        guard change.next.isLiveAgent, change.previous != .unknown, !change.previous.isLiveAgent else { return }
        recorded.insert(.queued(seq: seq))
    }

    /// `left:true` dari `leave-agent` selagi `state` antre atau dilayani agen, sebelum event `state`-nya tiba: posisi
    /// tunggu di `seq` terakhir yang diketahui; nil `seq` = belum ada apa pun. Tidak dibuang saat event keluar resmi
    /// tiba: scan menggantinya dengan event itu bila masih sesi yang sama, dan tetap memakainya bila sesi sudah ditutup
    /// jawaban bot atau antrean baru (event keluarnya terlewat replay).
    mutating func leave(_ state: ConversationState, afterSeq seq: Int?) {
        guard let seq else { return }
        recorded.insert(.leaving(seq: seq, isServed: state == .agentActive))
    }
}
