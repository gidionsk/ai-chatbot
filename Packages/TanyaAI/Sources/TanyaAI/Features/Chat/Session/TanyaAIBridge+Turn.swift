//
//  TanyaAIBridge+Turn.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// Satu pertanyaan per waktu selama dilayani bot. Bubble pertanyaan tampil saat itu juga dan tombol langsung
    /// menjadi stop; salinan dari stream menggantikannya tanpa jeda. Gagal kirim = bubble gagal (tanpa retry) dan
    /// kunci dibuka.
    /// Nil = ditolak tanpa diteruskan ke host (belum siap atau masih menunggu jawaban), draft tetap di composer.
    /// Task selesai setelah respons kirim diproses. Selama antre atau dilayani agen tidak ada `turn_end`, jadi kirim
    /// tidak dikunci dan tombol tidak menjadi stop.
    @discardableResult
    func send(_ text: String) -> Task<Void, Never>? {
        guard !isAwaitingReply, isReady, let conversationID else { return nil }
        // Penanda pertanyaan ini: respons yang datang setelah turn berganti tidak mengubah turn yang baru.
        let clientMessageID = UUID().uuidString
        if !conversationState.isLiveAgent {
            turn.start(clientMessageID: clientMessageID)
        }
        localQuestions.append(LocalQuestion(id: clientMessageID, text: text, afterSeq: messages.latestSeq))
        latestSentQuestionID = clientMessageID
        return Task {
            await deliver(text, clientMessageID: clientMessageID, conversationID: conversationID)
        }
    }

    /// Stop: `canceled:true` menunggu `turn_end` di stream (tombstone pertanyaan ikut datang); `canceled:false` =
    /// gateway tidak punya turn aktif, jadi kunci dibuka di sini karena `turn_end` tidak akan datang. Sebelum
    /// ack, cancel ditahan dan dikirim saat ack tiba. Gagal = stop bisa ditekan lagi (cancel idempoten).
    func cancelTurn() async {
        guard let clientMessageID = turn.startCanceling(), turn.isAccepted else { return }
        await requestCancel(clientMessageID: clientMessageID)
    }

    /// Salinan dari stream atau history sudah ada: bubble lokal dilepas. Daftar hanya diubah bila memang
    /// berubah, supaya pesan lain tidak memicu render ulang.
    /// ID salinannya dicatat: salinan kiriman sendiri bukan pesan masuk (lihat `sentMessageIDs`).
    func removeDeliveredQuestions() {
        let copies = localQuestions.map { $0.copy(in: messages)?.id }
        guard copies.contains(where: { $0 != nil }) else { return }
        sentMessageIDs.formUnion(copies.compactMap { $0 })
        localQuestions = zip(localQuestions, copies).filter { $0.1 == nil }.map(\.0)
    }
}

// MARK: - Turn

private extension TanyaAIBridge {
    func deliver(_ text: String, clientMessageID: String, conversationID: String) async {
        do {
            let data = try await transport.sendMessage(
                conversationID: conversationID, clientMessageID: clientMessageID, text: text
            )
            let ack = try? JSONDecoder.wire.decode(WireEnvelope<WireSendAck>.self, from: data).data
            let seq = ack.flatMap { Int($0.seq) }
            turn.accept(questionSeq: seq, for: clientMessageID)
            updateQuestion(clientMessageID) { $0.seq = seq }
            // Pertanyaan bisa datang lebih dulu tanpa `client_msg_id`; seq dari ack baru bisa mencocokkannya.
            removeDeliveredQuestions()
            if turn.isCanceling(clientMessageID: clientMessageID) {
                await requestCancel(clientMessageID: clientMessageID)
            }
        } catch {
            turn.cancel(clientMessageID: clientMessageID)
            updateQuestion(clientMessageID) { $0.isFailed = true }
            didFailRequest(error, conversationID: conversationID)
        }
    }

    func requestCancel(clientMessageID: String) async {
        guard let conversationID else { return }
        do {
            let data = try await transport.cancelTurn(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireCancel>.self, from: data).data
            if !result.isCanceled {
                turn.cancel(clientMessageID: clientMessageID)
            }
        } catch {
            turn.stopCanceling(clientMessageID: clientMessageID)
            didFailRequest(error, conversationID: conversationID)
        }
    }

    /// Pertanyaan lama yang sudah dilepas (percakapan berganti atau sudah datang dari stream) diabaikan.
    func updateQuestion(_ clientMessageID: String, _ change: (inout LocalQuestion) -> Void) {
        guard let index = localQuestions.firstIndex(where: { $0.id == clientMessageID }) else { return }
        change(&localQuestions[index])
    }
}
