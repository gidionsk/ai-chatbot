//
//  WireEnvelope.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// Envelope sukses gateway `{success:true, data}`. Respons gagal sudah dilempar host sebagai
/// `TanyaAITransportError`, jadi hanya `data` yang dibaca.
struct WireEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
}
