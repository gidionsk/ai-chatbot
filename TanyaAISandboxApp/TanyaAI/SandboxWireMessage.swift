//
//  SandboxWireMessage.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Objek `Message` gateway versi tiruan; di-encode snake_case seperti respons ICT.
struct SandboxWireMessage: Encodable {
    static let customer = "customer"
    static let bot = "bot"
    static let active = "active"
    /// Tombstone pertanyaan yang dihentikan; dikirim ulang dengan `message_id` sama.
    static let canceled = "canceled"

    let messageId: String
    let seq: String
    let direction: String
    let type = "text"
    let payload: String
    let status: String
    let clientMsgId: String?
    let createdAt = ISO8601DateFormatter().string(from: Date())
}
