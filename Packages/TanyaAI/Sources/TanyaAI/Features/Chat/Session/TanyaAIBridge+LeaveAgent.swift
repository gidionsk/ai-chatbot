//
//  TanyaAIBridge+LeaveAgent.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// Tombol batal dan End Session tidak dikirim dua kali untuk antrean atau sesi yang sama. Request milik antrean
    /// atau sesi yang sudah berganti tidak mengunci yang baru.
    var isLeavingAgent: Bool { leavingAgentScope == liveAgentScope }

    var liveAgentScope: LiveAgentScope {
        LiveAgentScope(conversationID: conversationID, state: conversationState, queueStartSeq: queueStartSeq)
    }

    /// `leave-agent` untuk "Batalkan" di kartu antre dan "End Session" di bar sesi agen (keputusan user 19 November
    /// 2026: keduanya memakai endpoint yang sama). `left:true` = langsung kembali ke bot tanpa menunggu event
    /// `state`; kartu penutup datang dari stream. `left:false` = sudah tidak antre/dilayani, state dari stream. 409
    /// atau gagal lain = tombol aktif lagi sampai event `state` menyembunyikannya. Respons milik percakapan yang sudah
    /// diganti init (reconnect) diabaikan, kecuali 401 yang berlaku untuk sesi. `left:true` yang datang setelah
    /// antrean atau sesi tempat request dimulai sudah berganti (state lain atau acuan antrean baru, lihat
    /// `markQueueStart`) juga diabaikan; state berikutnya tetap datang dari stream.
    func leaveAgent() async {
        guard conversationState.isLiveAgent, !isLeavingAgent, let conversationID else { return }
        let scope = liveAgentScope
        leavingAgentScope = scope
        defer { finishLeaving(scope) }
        do {
            let data = try await transport.leaveAgent(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireLeaveAgent>.self, from: data).data
            guard result.isLeft, liveAgentScope == scope else { return }
            conversationState = .assistantActive
        } catch {
            didFailRequest(error, conversationID: conversationID)
        }
    }

    /// Hanya status request milik `scope` yang dilepas; request antrean atau sesi berikutnya tetap berjalan.
    private func finishLeaving(_ scope: LiveAgentScope) {
        guard leavingAgentScope == scope else { return }
        leavingAgentScope = nil
    }
}
