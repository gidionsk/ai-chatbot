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
    /// Respons milik percakapan yang sudah diganti init (reconnect) diabaikan, kecuali 401 yang berlaku untuk sesi.
    func leaveAgentQueue() async {
        guard conversationState == .agentQueued, !isLeavingAgentQueue, let conversationID else { return }
        isLeavingAgentQueue = true
        defer { isLeavingAgentQueue = false }
        do {
            let data = try await transport.leaveAgent(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireLeaveAgent>.self, from: data).data
            guard result.isLeft, self.conversationID == conversationID, conversationState == .agentQueued else {
                return
            }
            conversationState = .assistantActive
        } catch {
            didFailRequest(error, conversationID: conversationID)
        }
    }
}

// MARK: - Notices

extension TanyaAIBridge {
    /// Kartu yang tampil di daftar. Kartu antre hanya selama `AGENT_QUEUED`: yang terbaru dari stream, atau di akhir
    /// daftar bila event-nya tidak ikut replay. Dari history ditambahkan kartu selesai untuk sesi agen dan kartu
    /// "tidak dilanjutkan" untuk serah terima tanpa agen, bila stream tidak memberi kartu penutupnya. Kartu antre
    /// bukan penutup: setelah antre selesai kartunya tersembunyi. `seq` menjadi id baris, jadi kartu ber-`seq` sama
    /// hanya tampil sekali: table crash bila menerima id ganda, dan itu terjadi bila `id:` SSE dan `seq` pesan tidak
    /// berasal dari satu urutan. Yang dipertahankan urut kepentingannya: kartu antre yang sedang aktif (tombol
    /// batalnya ikut kartu ini), lalu kartu dari stream, baru kartu turunan history.
    var visibleLiveAgentNotices: [LiveAgentNotice] {
        let closing = liveAgentNotices.filter { $0.kind != .connecting }
        let isSettled = !conversationState.isLiveAgent && !isAwaitingReply
        var notices = activeQueueNotices + closing
        notices += messages.endedAgentSessions(isOngoing: conversationState == .agentActive, closedBy: closing)
        notices += messages.unfinishedHandovers(isSettled: isSettled, closedBy: closing)
        var seenSeqs = Set<Int>()
        return notices.filter { seenSeqs.insert($0.seq).inserted }.sorted { $0.seq < $1.seq }
    }

    /// Kartu antre selama `AGENT_QUEUED`: yang terbaru dari stream, atau di akhir daftar bila event-nya tidak ikut
    /// replay. Kosong di luar antre.
    private var activeQueueNotices: [LiveAgentNotice] {
        guard conversationState == .agentQueued else { return [] }
        let latest = liveAgentNotices.last { $0.kind == .connecting }
        return [latest ?? LiveAgentNotice(kind: .connecting, seq: .max)]
    }

    /// Pemicu ikut ke bawah bila pembaca di ujung daftar: pesan masuk terbaru, kartu live agent terbaru yang tampil,
    /// atau indikator mengetik. Hanya perubahannya yang dipakai, bukan isinya; nil selama belum ada apa pun.
    /// Kartu antre (dan tombol batalnya) baru tampil saat event `state` tiba setelah event `system`-nya, jadi yang
    /// dipakai kartu yang tampil, bukan kartu terakhir dari stream: `latestNotice` = `visibleLiveAgentNotices.last`,
    /// diberikan pemanggil supaya daftar kartu cukup dihitung sekali per render.
    func incomingContentID(latestNotice: LiveAgentNotice?) -> String? {
        let typing = isAgentTyping ? isAgentTyping.description : nil
        let notice = latestNotice.map { $0.kind.rawValue + String($0.seq) }
        let parts = [latestIncomingMessageID, notice, typing].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined()
    }
}

// MARK: - Typing

extension TanyaAIBridge {
    /// Dari init (termasuk setelah reconnect) maupun event `state`: di luar antre/agen tidak ada agen yang mengetik,
    /// dan di luar `AGENT_ACTIVE` tidak ada yang menerima sinyal mengetik nasabah.
    func didChangeConversationState() {
        if !conversationState.isLiveAgent {
            showAgentTyping(false)
        }
        guard conversationState != .agentActive else { return }
        resetUserTyping()
    }

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

// MARK: - User typing

extension TanyaAIBridge {
    /// Dari composer: `true` di setiap ketikan selama draft berisi, `false` saat draft kosong (termasuk setelah
    /// terkirim) atau composer hilang. Hanya diteruskan ke agen selama `AGENT_ACTIVE` dan sesi hidup (contract
    /// §7.7): `true` saat mulai, diulang paling cepat tiap `typingRefresh` agar tidak kedaluwarsa di server, dan
    /// `false` setelah `typingIdle` tanpa ketikan.
    func userTypingChanged(_ isTyping: Bool) {
        guard isTyping, isReady, conversationState == .agentActive else { return stopUserTyping() }
        userTypingIdle?.cancel()
        userTypingIdle = Task { [weak self, sleep] in
            guard (try? await sleep(ChatWire.typingIdle)) != nil, !Task.isCancelled else { return }
            self?.stopUserTyping()
        }
        guard userTypingRefresh == nil else { return }
        deliverUserTyping(true)
        userTypingRefresh = Task { [weak self, sleep] in
            guard (try? await sleep(ChatWire.typingRefresh)) != nil, !Task.isCancelled else { return }
            self?.userTypingRefresh = nil
        }
    }

    /// Berhenti mengetik selagi masih dengan agen: kabarkan `false` bila `true` pernah dikirim.
    func stopUserTyping() {
        cancelUserTypingTimers()
        guard userTyping.isTyping else { return }
        deliverUserTyping(false)
    }

    /// Agen selesai, percakapan berganti, atau sesi berakhir: lupakan status dan sinyal yang menunggu tanpa kiriman,
    /// karena tidak ada lagi yang menerimanya.
    func resetUserTyping() {
        cancelUserTypingTimers()
        userTyping = UserTypingSignal()
    }
}

private extension TanyaAIBridge {
    /// Satu pengirim berurutan agar `false` tidak mendahului `true`. Sinyal yang datang selama kiriman berjalan
    /// digabung menjadi yang terbaru. Sinyal ini tidak disimpan server, jadi gagal diabaikan; hanya 401 yang
    /// mengakhiri sesi seperti jalur lain.
    func deliverUserTyping(_ isTyping: Bool) {
        userTyping.queue(isTyping)
        guard userTypingDelivery == nil else { return }
        userTypingDelivery = Task { [weak self] in
            while let signal = self?.nextUserTypingSignal(), let transport = self?.transport {
                do {
                    try await transport.sendTyping(conversationID: signal.conversationID, isTyping: signal.isTyping)
                } catch {
                    self?.didFailUserTyping(error)
                }
            }
            self?.userTypingDelivery = nil
        }
    }

    /// Diperiksa tepat sebelum dikirim: masih dengan agen dan sesi hidup. Percakapannya yang terbaru, karena
    /// pergantian percakapan sudah membuang sinyal yang menunggu.
    func nextUserTypingSignal() -> (conversationID: String, isTyping: Bool)? {
        let isDeliverable = isReady && conversationState == .agentActive
        guard let isTyping = userTyping.takeNext(isDeliverable: isDeliverable), let conversationID else { return nil }
        return (conversationID, isTyping)
    }

    /// Pewaktu yang dibatalkan tidak mengubah apa pun lagi, jadi penandanya dikosongkan di sini.
    func cancelUserTypingTimers() {
        userTypingIdle?.cancel()
        userTypingRefresh?.cancel()
        userTypingRefresh = nil
    }

    func didFailUserTyping(_ error: Error) {
        guard case let .response(statusCode, _)? = error as? TanyaAITransportError,
            ChatBackoff.isUnauthorized(statusCode: statusCode)
        else { return }
        expireSession()
    }
}
