//
//  WireSendAck.swift
//  TanyaAI
//
//  Created by Wendra on 29/10/26.
//

/// `data` ack 202 `POST /chat/messages`: seq pertanyaan yang tersimpan, penanda turn yang ditunggu.
struct WireSendAck: Decodable {
    let messageId: String
    let seq: String
}
