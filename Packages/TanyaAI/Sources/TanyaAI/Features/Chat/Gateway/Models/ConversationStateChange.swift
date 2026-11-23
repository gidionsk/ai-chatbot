//
//  ConversationStateChange.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Event `state` dari stream: state asal, state tujuan, dan `id:` frame-nya. `seq` berbagi urutan dengan pesan, jadi
/// perpindahan keluar dari antre atau agen menandai posisi akhir sesi agen di daftar.
struct ConversationStateChange: Equatable {
    let previous: ConversationState
    let next: ConversationState
    let seq: Int?

    /// Posisi akhir sesi agen: frame ini memindahkan percakapan dari antre atau agen ke state lain. Pesan nasabah
    /// sebelum frame ini, termasuk yang dikirim sebelum agen manusia bergabung, masih milik sesi agen.
    var agentExitSeq: Int? {
        guard previous.isLiveAgent, !next.isLiveAgent else { return nil }
        return seq
    }
}
