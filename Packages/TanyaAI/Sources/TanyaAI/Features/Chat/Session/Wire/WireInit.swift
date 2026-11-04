//
//  WireInit.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `data` dari `POST /chat/init`. `message_id`/`seq` hanya terisi bila init membawa pesan pertama (belum dipakai).
struct WireInit: Decodable {
    let conversationId: String
    let state: ConversationState
}
