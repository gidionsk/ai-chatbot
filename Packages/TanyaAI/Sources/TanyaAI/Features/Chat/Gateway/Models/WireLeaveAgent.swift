//
//  WireLeaveAgent.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` 200 `POST /v1/chat/conversations/{id}/leave-agent`. True = keluar dari antrean; event `state` dan
/// `queue_canceled` menyusul di stream. False = tidak sedang antre (no-op).
struct WireLeaveAgent: Decodable {
    let isLeft: Bool

    private enum CodingKeys: String, CodingKey {
        case isLeft = "left"
    }
}
