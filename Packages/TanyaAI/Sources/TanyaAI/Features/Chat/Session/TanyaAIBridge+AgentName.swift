//
//  TanyaAIBridge+AgentName.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Foundation

// MARK: - Agent name

extension TanyaAIBridge {
    /// Bar sesi agen hanya saat `AGENT_ACTIVE` dan nama agen sudah datang. Di UAT `AGENT_ACTIVE` dan `agent_joined`
    /// dengan `agent: null` datang sebelum sapaan otomatis dan pesan antre, jadi state saja belum berarti agen manusia
    /// (keputusan user 20 November 2026). Init tidak membawa nama, jadi saat dibuka lagi bar menunggu nama dari replay.
    var isHumanAgentActive: Bool { conversationState == .agentActive && agentName != nil }

    /// Nama dari event `state` menuju `AGENT_ACTIVE` atau `agent_joined`, mana yang lebih dulu. Null atau kosong
    /// diabaikan; agen berikutnya (transfer) mengganti nama lama.
    func rememberAgent(named name: String?) {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
        agentName = name
    }

    /// Dari `didChangeConversationState`: nama dilupakan di luar antre/agen dan saat antrean baru dimulai. Antre ke
    /// agen bergabung dan init berulang dalam state yang sama mempertahankannya, karena `agent_joined` bisa
    /// mendahului event `state`.
    func forgetAgent(previous: ConversationState) {
        let isNewQueue = conversationState == .agentQueued && previous != .agentQueued
        guard !conversationState.isLiveAgent || isNewQueue, agentName != nil else { return }
        agentName = nil
    }
}
