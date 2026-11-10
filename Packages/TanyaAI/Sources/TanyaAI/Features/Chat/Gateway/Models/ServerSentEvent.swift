//
//  ServerSentEvent.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// Satu frame SSE utuh: `id:` (seq percakapan), `event:`, dan `data:` berupa JSON satu baris.
struct ServerSentEvent: Equatable {
    let id: String?
    let name: String
    let data: String
}
