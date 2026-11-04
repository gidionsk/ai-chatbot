//
//  TanyaAIChatService.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import Foundation
import TanyaAI

/// Tiruan service chat-gateway Byon (Alamofire): gaya callback, body mentah tanpa envelope host, dan callback
/// selalu di main queue. Semua state disentuh di main queue, jadi aman dipanggil dari thread mana pun.
final class TanyaAIChatService {
    private let options: SandboxOptions
    /// Meniru blocker jaringan host: kirim tanpa internet juga dilaporkan ke halaman host.
    private let onSubmissionFailed: (Error) -> Void
    private var frames: SandboxGatewayFrames
    private var onLine: ((String) -> Void)?
    /// Pertanyaan yang jawabannya belum selesai; nil = tidak ada turn aktif (cancel = no-op).
    private var pendingQuestion: SandboxWireMessage?
    /// Kemunculan pertanyaan dan jawaban yang dijadwalkan; dibatalkan saat stop.
    private var pendingWork: [DispatchWorkItem] = []

    init(options: SandboxOptions, onSubmissionFailed: @escaping (Error) -> Void) {
        self.options = options
        self.onSubmissionFailed = onSubmissionFailed
        frames = SandboxGatewayFrames(seq: options.isShowingHistory ? SandboxGatewayFrames.historyLatestSeq : .zero)
    }

    func initialize(onSuccess: @escaping (Data) -> Void, onFailed: @escaping (Error) -> Void) {
        DispatchQueue.main.async { onSuccess(SandboxGatewayFrames.initialize) }
    }

    /// `--with-history`: fixture dua tanggal; selain itu percakapan kosong (sambutan tampil).
    func history(
        conversationID: String, before: String?, limit: Int,
        onSuccess: @escaping (Data) -> Void, onFailed: @escaping (Error) -> Void
    ) {
        DispatchQueue.main.async { [options] in
            guard options.isShowingHistory, let url = SandboxFixtureFile.tanyaAIHistoryDummy.url else {
                onSuccess(SandboxGatewayFrames.emptyHistory)
                return
            }
            do {
                onSuccess(try Data(contentsOf: url))
            } catch {
                onFailed(error)
            }
        }
    }

    func sendMessage(
        conversationID: String, clientMessageID: String, text: String,
        onSuccess: @escaping (Data) -> Void, onFailed: @escaping (Error) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.options.isOffline else {
                let error = URLError(.notConnectedToInternet)
                self.onSubmissionFailed(error)
                onFailed(error)
                return
            }
            guard !self.options.isRejectingSend else {
                onFailed(
                    TanyaAITransportError.response(
                        statusCode: SandboxGatewayFrames.badRequestStatus, body: SandboxGatewayFrames.badRequest
                    ))
                return
            }
            onSuccess(self.accept(text, clientMessageID: clientMessageID))
        }
    }

    /// Stop: turn yang berjalan dihentikan (tombstone pertanyaan + `turn_end` canceled menyusul di stream setelah
    /// respons), atau no-op bila tidak ada turn aktif.
    func cancelTurn(
        conversationID: String, onSuccess: @escaping (Data) -> Void, onFailed: @escaping (Error) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let question = self.pendingQuestion else {
                onSuccess(SandboxGatewayFrames.nothingToCancel)
                return
            }
            self.pendingWork.forEach { $0.cancel() }
            onSuccess(SandboxGatewayFrames.canceled)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.emit(self.frames.tombstone(of: question))
                self.finishTurn(status: SandboxGatewayFrames.canceledStatus)
            }
        }
    }

    /// Stream SSE tiruan: `onLine` per baris lengkap. Kembalian dipakai pemanggil untuk menutup stream,
    /// sama seperti `DataStreamRequest.cancel()` di Byon.
    func events(
        conversationID: String, lastEventID: String?,
        onLine: @escaping (String) -> Void, onComplete: @escaping (Error?) -> Void
    ) -> SandboxStreamRequest {
        DispatchQueue.main.async { [weak self] in
            self?.onLine = onLine
            onLine(SandboxGatewayFrames.connected)
        }
        return SandboxStreamRequest { [weak self] in
            DispatchQueue.main.async { self?.onLine = nil }
        }
    }
}

// MARK: - Gateway tiruan

private extension TanyaAIChatService {
    /// Pertanyaan tampil di stream setelah jeda pendek, lalu dijawab setelah jeda berikutnya, seperti gateway asli.
    /// `--hold-reply`: jawaban tidak pernah datang, sehingga stop bisa diuji.
    func accept(_ text: String, clientMessageID: String) -> Data {
        let ack = frames.ack()
        let question = frames.newMessage(
            direction: SandboxWireMessage.customer, text: text, clientMessageID: clientMessageID
        )
        pendingQuestion = question
        schedule(after: SandboxOptions.echoDelay) { $0.emit($0.frames.frame(question)) }
        if !options.isHoldingReply {
            schedule(after: SandboxOptions.echoDelay + SandboxOptions.replyDelay) { service in
                let reply = SandboxGatewayFrames.reply(to: text)
                service.emit(service.frames.message(direction: SandboxWireMessage.bot, text: reply))
                service.finishTurn()
            }
        }
        return ack
    }

    func finishTurn(status: String = SandboxGatewayFrames.completedStatus) {
        pendingQuestion = nil
        pendingWork = []
        emit(frames.turnEnd(status: status))
    }

    func schedule(after delay: TimeInterval, _ work: @escaping (TanyaAIChatService) -> Void) {
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            work(self)
        }
        pendingWork.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func emit(_ lines: [String]) {
        lines.forEach { onLine?($0) }
    }
}
