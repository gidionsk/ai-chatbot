//
//  AgentSessionExits.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Posisi akhir sesi agen yang diterima selama halaman terbuka. History tidak membawa event `state`, jadi posisi ini
/// hanya ada dari stream, termasuk replay setelah history dimuat; kartu selesai memakainya sebelum menebak dari pesan.
struct AgentSessionExits: Equatable {
    /// Event `state` yang keluar dari antre atau agen, serta posisi tunggu dan awal antrean baru bila event keluarnya
    /// terlewat (lihat `enter`).
    private(set) var recorded: Set<AgentSessionMark> = []
    /// `leave-agent` sudah menjawab `left:true` tetapi event `state`-nya belum tiba: posisi di `seq` terakhir yang
    /// diketahui saat itu (`AgentSessionMark.leaving`). Pertanyaan ke bot yang dikirim sesudahnya tetap di bawah kartu
    /// selesai.
    private(set) var pending: AgentSessionMark?

    /// Penanda keluar yang dipakai kartu selesai, urut naik.
    var marks: [AgentSessionMark] { (Array(recorded) + [pending].compactMap { $0 }).sorted() }

    /// Event `state` dari stream. Keluar dari antre atau agen dicatat posisinya dan menggantikan posisi tunggu.
    mutating func record(_ change: ConversationStateChange) {
        guard let seq = change.agentExitSeq else { return enter(change) }
        recorded.insert(.exit(seq: seq, isServed: change.previous == .agentActive))
        pending = nil
    }

    /// `left:true` dari `leave-agent` selagi `state` antre atau dilayani agen; nil `seq` = belum ada apa pun.
    mutating func leave(_ state: ConversationState, afterSeq seq: Int?) {
        pending = seq.map { .leaving(seq: $0, isServed: state == .agentActive) }
    }

    /// Masuk antre atau agen sebelum event keluar resmi diterima (mis. terlewat karena replay setelah reconnect dimulai
    /// sesudahnya): posisi tunggu tetap menjadi akhir sesi lama, dan event masuk dicatat sebagai awal antrean baru
    /// supaya pesan agen sesi baru tidak ikut sesi lama.
    private mutating func enter(_ change: ConversationStateChange) {
        guard change.next.isLiveAgent, let pending else { return }
        recorded.insert(pending)
        if let seq = change.seq {
            recorded.insert(.queued(seq: seq))
        }
        self.pending = nil
    }
}
