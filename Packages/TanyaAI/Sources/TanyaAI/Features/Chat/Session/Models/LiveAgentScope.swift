//
//  LiveAgentScope.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Antrean atau sesi agen tempat request `leave-agent` dimulai: state dan acuan awal antrean (`queueStartSeq`).
/// Nilai yang berbeda berarti antrean atau sesi itu sudah berganti, jadi respons dan status request-nya bukan milik
/// antrean atau sesi yang sekarang.
struct LiveAgentScope: Equatable {
    let state: ConversationState
    let queueStartSeq: Int?
}
