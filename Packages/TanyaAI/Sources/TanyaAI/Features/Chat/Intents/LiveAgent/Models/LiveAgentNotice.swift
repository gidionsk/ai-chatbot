//
//  LiveAgentNotice.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// Kartu status live agent di posisi `seq` event-nya. Hanya hidup selama halaman terbuka: history tidak
/// membawa event `system`, jadi kartu lama hanya kembali bila masih ikut replay stream.
struct LiveAgentNotice: Equatable {
    let kind: LiveAgentNoticeKind
    /// `id:` frame SSE, satu urutan dengan `seq` pesan.
    let seq: Int
}
