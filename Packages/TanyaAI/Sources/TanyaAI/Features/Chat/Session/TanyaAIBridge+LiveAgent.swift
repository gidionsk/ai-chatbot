//
//  TanyaAIBridge+LiveAgent.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// "Batalkan proses ini" selama antre. `left:true` = langsung kembali ke bot tanpa menunggu event `state`;
    /// kartu batal datang dari stream (`queue_canceled`). `left:false` = sudah tidak antre, state dari stream.
    /// 409 = agen sudah bergabung; tombol kembali aktif sampai event `state` menyembunyikannya.
    func leaveAgentQueue() async {
        guard conversationState == .agentQueued, !isLeavingAgentQueue, let conversationID else { return }
        isLeavingAgentQueue = true
        defer { isLeavingAgentQueue = false }
        do {
            let data = try await transport.leaveAgent(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireLeaveAgent>.self, from: data).data
            guard result.isLeft, conversationState == .agentQueued else { return }
            conversationState = .assistantActive
        } catch {
            didFailRequest(error)
        }
    }
}

// MARK: - Notices

extension TanyaAIBridge {
    /// Kartu yang tampil di daftar. Kartu antre hanya selama `AGENT_QUEUED`: yang terbaru dari stream, atau di akhir
    /// daftar bila event-nya tidak ikut replay. Kartu selesai dari history ditambahkan untuk sesi agen yang tidak
    /// punya kartu penutup dari stream.
    var visibleLiveAgentNotices: [LiveAgentNotice] {
        var notices = liveAgentNotices.filter { $0.kind != .connecting }
        notices += messages.endedAgentSessions(isOngoing: conversationState == .agentActive, closedBy: notices)
        if conversationState == .agentQueued {
            let latest = liveAgentNotices.last { $0.kind == .connecting }
            notices.append(latest ?? LiveAgentNotice(kind: .connecting, seq: .max))
        }
        return notices.sorted { $0.seq < $1.seq }
    }

    /// Pemicu ikut ke bawah bila pembaca di ujung daftar: pesan masuk terbaru, kartu live agent terbaru yang tampil,
    /// atau indikator mengetik. Hanya perubahannya yang dipakai, bukan isinya; nil selama belum ada apa pun.
    /// Kartu antre (dan tombol batalnya) baru tampil saat event `state` tiba setelah event `system`-nya, jadi yang
    /// dipakai kartu yang tampil, bukan kartu terakhir dari stream.
    var latestIncomingContentID: String? {
        let typing = isAgentTyping ? isAgentTyping.description : nil
        let notice = visibleLiveAgentNotices.last.map { $0.kind.rawValue + String($0.seq) }
        let parts = [latestIncomingMessageID, notice, typing].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined()
    }
}

// MARK: - Typing

extension TanyaAIBridge {
    /// Event `typing` tidak tersimpan, jadi indikator dihapus sendiri setelah `lifetime` bila kabar berikutnya
    /// (mis. `typing:false`) hilang. Event baru mengganti penghapus yang lama.
    func showAgentTyping(_ isTyping: Bool, lifetime: TimeInterval = .zero) {
        agentTypingExpiry?.cancel()
        agentTypingExpiry = nil
        if isAgentTyping != isTyping {
            isAgentTyping = isTyping
        }
        guard isTyping else { return }
        agentTypingExpiry = Task { [weak self, sleep] in
            guard (try? await sleep(lifetime)) != nil, !Task.isCancelled else { return }
            self?.isAgentTyping = false
        }
    }
}
