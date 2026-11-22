//
//  AgentSessionKey.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Antrean atau sesi agen yang dilihat nasabah: percakapan dan acuan awal antrean (`markQueueStart`). Tetap sama saat
/// antre berlanjut menjadi dilayani agen; berganti saat percakapan berganti atau init menandai acuan baru, karena
/// antrean bisa sudah berganti selama putus. Berbeda dengan `LiveAgentScope`, state tidak ikut, supaya konfirmasi End
/// Session yang dibuka saat antre tetap berlaku setelah agen bergabung.
struct AgentSessionKey: Hashable {
    let conversationID: String?
    let queueStartSeq: Int?
}
