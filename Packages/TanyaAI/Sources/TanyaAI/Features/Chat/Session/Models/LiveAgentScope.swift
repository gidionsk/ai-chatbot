//
//  LiveAgentScope.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Antrean atau sesi agen tempat request `leave-agent` dimulai: percakapan, state, dan acuan awal antrean
/// (`queueStartSeq`). Nilai yang berbeda berarti antrean atau sesi itu sudah berganti, jadi respons dan status
/// request-nya bukan milik antrean atau sesi yang sekarang. `seq` hanya bermakna di dalam satu percakapan.
struct LiveAgentScope: Equatable {
    let conversationID: String?
    let state: ConversationState
    let queueStartSeq: Int?
}
