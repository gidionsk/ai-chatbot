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
    /// Kartu yang tampil di daftar: kartu pembuka sesi yang sedang berjalan selama belum ada pesan agen, kartu penutup
    /// dari stream, lalu dari history kartu "Connected" tiap sesi agen, kartu selesai, dan kartu "tidak dilanjutkan"
    /// untuk serah terima tanpa agen, bila stream tidak memberi kartu penutupnya. Event antre dan agen bergabung tidak
    /// tampil sendiri; keduanya hanya menentukan kartu pembuka. `seq` menjadi id baris, jadi kartu ber-`seq` sama hanya
    /// tampil sekali: table crash bila menerima id ganda, dan itu terjadi bila `id:` SSE dan `seq` pesan tidak berasal
    /// dari satu urutan. Yang dipertahankan urut kepentingannya: kartu pembuka yang sedang berjalan (tombol batalnya
    /// ikut kartu ini), lalu kartu dari stream, baru kartu turunan history.
    var visibleLiveAgentNotices: [LiveAgentNotice] {
        let streamNotices = liveAgentNotices.filter { $0.kind != .connecting }
        let closing = streamNotices.filter { $0.kind != .joined }
        let isSettled = !conversationState.isLiveAgent && !isAwaitingReply
        var notices = openingNotices + closing
        notices += messages.connectedAgentSessions(openedBy: liveAgentNotices.filter { $0.kind == .connecting })
        notices += messages.endedAgentSessions(isOngoing: conversationState.isLiveAgent, closedBy: closing)
        notices += messages.unfinishedHandovers(isSettled: isSettled, closedBy: streamNotices)
            .filter { !streamedHandoverSeqs.contains($0.seq) }
        var seenSeqs = Set<Int>()
        return notices.filter { seenSeqs.insert($0.seq).inserted }.sorted { $0.seq < $1.seq }
    }

    /// "Mencari customer assistant..." selama antre setelah sapaan otomatis agen (pesan agen sebelum agen bergabung),
    /// sampai agen bergabung atau antrean ditutup. Indikator agen mengetik didahulukan.
    var isSearchingAgent: Bool {
        guard conversationState == .agentQueued, !isAgentTyping, isAgentMessageInSession else { return false }
        return !liveAgentNotices.contains { $0.kind != .connecting && $0.seq > sessionStartSeq }
    }

    /// Kartu pembuka sesi yang sedang berjalan selama belum ada pesan agen: "Switching" dengan tombol batal selama
    /// antre, "Connected" begitu agen bergabung (`agent_joined` bisa mendahului event `state`). Setelah pesan agen
    /// pertama, kartunya diturunkan dari pesan di posisi yang sama. Kosong begitu antrean ditutup event lain (batal,
    /// antre habis, agen tidak tersedia), karena event `state` bisa terlambat dan kartu tidak boleh tampil bersama
    /// penggantinya. Event antre dipakai sebagai posisi hanya bila milik antrean ini: setelah jawaban bot terakhir (bot
    /// tidak menjawab selama antre) dan belum ditutup event lain. Selain itu pembukanya terlewat, jadi kartu di akhir
    /// daftar.
    private var openingNotices: [LiveAgentNotice] {
        guard conversationState.isLiveAgent, !isAgentMessageInSession else { return [] }
        let closing = liveAgentNotices.filter { $0.kind != .connecting && $0.kind != .joined }
        guard !closing.contains(where: { $0.seq > sessionStartSeq }) else { return [] }
        let isJoined = liveAgentNotices.contains { $0.kind == .joined && $0.seq > sessionStartSeq }
        let kind: LiveAgentNoticeKind = conversationState == .agentActive || isJoined ? .connected : .connecting
        let assistantSeq = lastAssistantSeq
        let opener = liveAgentNotices.last { $0.kind == .connecting && $0.seq > assistantSeq }
        guard let opener, !closing.contains(where: { $0.seq > opener.seq }) else {
            return [LiveAgentNotice(kind: kind, seq: .max)]
        }
        return [LiveAgentNotice(kind: kind, seq: opener.seq)]
    }

    /// Pemicu ikut ke bawah bila pembaca di ujung daftar: pesan masuk terbaru, kartu live agent terbaru yang tampil,
    /// atau indikator mengetik dan mencari agen. Hanya perubahannya yang dipakai, bukan isinya; nil selama belum ada
    /// apa pun. Kartu antre (dan tombol batalnya) baru tampil saat event `state` tiba setelah event `system`-nya, jadi
    /// yang dipakai kartu yang tampil, bukan kartu terakhir dari stream: `latestNotice` =
    /// `visibleLiveAgentNotices.last`, diberikan pemanggil supaya daftar kartu cukup dihitung sekali per render.
    func incomingContentID(latestNotice: LiveAgentNotice?) -> String? {
        let typing = isAgentTyping ? String(describing: ChatListItemID.agentTyping) : nil
        let searching = isSearchingAgent ? String(describing: ChatListItemID.agentSearching) : nil
        let notice = latestNotice.map { $0.kind.rawValue + String($0.seq) }
        let parts = [latestIncomingMessageID, notice, typing, searching].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined()
    }
}

// MARK: - Typing

extension TanyaAIBridge {
    /// Acuan awal antrean untuk kartu pembuka dan indikator mencari agen: seq terakhir yang diketahui. Dipanggil saat
    /// stream memindahkan state ke antre (= seq event `state`) dan setiap init, karena antrean (atau percakapan) bisa
    /// sudah berganti selama putus walau nilai state-nya sama. Di luar antre acuannya dilupakan, supaya acuan dari
    /// percakapan lain tidak menyembunyikan kartu sesi agen yang dibuka langsung dari init.
    func markQueueStart() {
        guard conversationState == .agentQueued else {
            queueStartSeq = nil
            return
        }
        // `messages` sudah urut `seq` naik, jadi pesan terakhir = seq terbesar tanpa memindai seluruh history.
        queueStartSeq = [messages.last?.seq, eventCursor].compactMap { $0 }.max()
    }

    /// Dari init (termasuk setelah reconnect) maupun event `state`: di luar antre/agen tidak ada agen yang mengetik
    /// dan tidak ada yang menerima sinyal mengetik nasabah. Antre ke agen bergabung tetap satu sesi, jadi acuan antrean
    /// dan sinyal mengetik dipertahankan.
    func didChangeConversationState(previous: ConversationState) {
        if previous != .agentQueued {
            markQueueStart()
        }
        guard !conversationState.isLiveAgent else { return }
        showAgentTyping(false)
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
    /// terkirim) atau composer hilang. Hanya diteruskan selama antre atau dilayani agen dan sesi hidup (contract §7.7,
    /// diteruskan ke sistem agen di kedua state): `true` saat mulai, diulang paling cepat tiap `typingRefresh` agar
    /// tidak kedaluwarsa di server, dan `false` setelah `typingIdle` tanpa ketikan.
    func userTypingChanged(_ isTyping: Bool) {
        guard isTyping, isReady, conversationState.isLiveAgent else { return stopUserTyping() }
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

    /// Berhenti mengetik selagi masih antre atau dengan agen: kabarkan `false` bila `true` pernah dikirim.
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
                    self?.expireSessionIfUnauthorized(error)
                }
            }
            self?.userTypingDelivery = nil
        }
    }

    /// Diperiksa tepat sebelum dikirim: masih antre atau dengan agen dan sesi hidup. Percakapannya yang terbaru, karena
    /// pergantian percakapan sudah membuang sinyal yang menunggu.
    func nextUserTypingSignal() -> (conversationID: String, isTyping: Bool)? {
        let isDeliverable = isReady && conversationState.isLiveAgent
        guard let isTyping = userTyping.takeNext(isDeliverable: isDeliverable), let conversationID else { return nil }
        return (conversationID, isTyping)
    }

    /// Pewaktu yang dibatalkan tidak mengubah apa pun lagi, jadi penandanya dikosongkan di sini.
    func cancelUserTypingTimers() {
        userTypingIdle?.cancel()
        userTypingRefresh?.cancel()
        userTypingRefresh = nil
    }
}

// MARK: - Session reference

private extension TanyaAIBridge {
    /// `seq` jawaban bot terakhir; bot tidak menjawab selama antre atau dilayani agen.
    var lastAssistantSeq: Int { messages.last { $0.author == .assistant }?.seq ?? .min }

    /// Acuan awal sesi agen yang sedang berjalan: awal antrean (`markQueueStart`) atau jawaban bot terakhir, mana
    /// yang lebih baru. Event sebelum acuan ini milik antrean atau sesi sebelumnya.
    var sessionStartSeq: Int { Swift.max(queueStartSeq ?? .min, lastAssistantSeq) }

    /// Ada pesan agen setelah jawaban bot terakhir: sapaan otomatis selama antre, atau balasan agen.
    var isAgentMessageInSession: Bool {
        messages.last { $0.author == .assistant || $0.author == .agent }?.author == .agent
    }
}
