//
//  TanyaAIBridge+LeaveAgent.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// `leave-agent` untuk "Batalkan" di kartu antre dan "End Session" di bar sesi agen (keputusan user 19 November
    /// 2026: keduanya memakai endpoint yang sama). `left:true` = langsung kembali ke bot tanpa menunggu event
    /// `state`; kartu penutup datang dari stream. `left:false` = sudah tidak antre/dilayani, state dari stream. 409
    /// atau gagal lain = tombol aktif lagi sampai event `state` menyembunyikannya. Respons milik percakapan yang sudah
    /// diganti init (reconnect) diabaikan, kecuali 401 yang berlaku untuk sesi. `left:true` yang datang setelah
    /// antrean atau sesi tempat request dimulai sudah berganti (state lain atau acuan antrean baru, lihat
    /// `markQueueStart`) juga diabaikan; state berikutnya tetap datang dari stream.
    func leaveAgent() async {
        guard conversationState.isLiveAgent, !isLeavingAgent, let conversationID else { return }
        let startState = conversationState
        let startQueueSeq = queueStartSeq
        isLeavingAgent = true
        defer { isLeavingAgent = false }
        do {
            let data = try await transport.leaveAgent(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireLeaveAgent>.self, from: data).data
            guard result.isLeft, self.conversationID == conversationID, conversationState == startState,
                queueStartSeq == startQueueSeq
            else { return }
            conversationState = .assistantActive
        } catch {
            didFailRequest(error, conversationID: conversationID)
        }
    }
}
