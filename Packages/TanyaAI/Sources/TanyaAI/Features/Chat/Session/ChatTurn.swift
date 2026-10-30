//
//  ChatTurn.swift
//  TanyaAI
//
//  Created by Wendra on 29/10/26.
//

/// Satu pertanyaan per waktu. Hanya `turn_end` dengan `seq` setelah pertanyaan yang sedang ditunggu
/// (seq dari ack kirim) yang membuka kunci, jadi `turn_end` lama hasil replay setelah reconnect tidak
/// membuka kirim untuk pertanyaan baru. `turn_end` boleh datang sebelum ack (stream lebih cepat dari
/// respons HTTP); ia dicatat lalu dicocokkan saat ack tiba. Respons kirim yang datang terlambat
/// (pertanyaan lama, mis. sebelum percakapan berganti) dikenali lewat `client_message_id` dan diabaikan.
struct ChatTurn: Equatable {
    /// `client_message_id` pertanyaan yang ditunggu; nil = tidak menunggu.
    private var clientMessageID: String?
    /// Seq pertanyaan dari ack; nil selama ack belum diterima.
    private var questionSeq: Int?
    /// Seq `turn_end` terbesar sejak pertanyaan dikirim.
    private var latestEndSeq: Int?
    /// Pertanyaan yang ditunggu sudah datang dari stream atau history (bubble tampil).
    private var isQuestionShown = false
    /// Stop sudah ditekan dan belum selesai.
    private var isCanceling = false

    var isAwaiting: Bool { clientMessageID != nil }

    var phase: ChatTurnPhase {
        guard isAwaiting else { return .idle }
        if isCanceling { return .canceling }
        return isQuestionShown ? .awaitingReply : .sending
    }

    /// True bila pertanyaan yang ditunggu ada di `messages` tetapi belum ditandai tampil. Dicocokkan lewat
    /// `client_msg_id`, atau seq dari ack bila gateway tidak mengembalikan `client_msg_id`.
    func isQuestionArriving(in messages: [ChatMessage]) -> Bool {
        guard let clientMessageID, !isQuestionShown else { return false }
        return messages.last { message in
            message.author == .customer && (message.clientMessageID == clientMessageID || message.seq == questionSeq)
        } != nil
    }

    mutating func showQuestion() {
        isQuestionShown = true
    }

    /// Stop ditekan. Nil bila belum boleh (pertanyaan belum tampil) atau stop sudah diproses.
    mutating func startCanceling() -> String? {
        guard phase == .awaitingReply else { return nil }
        isCanceling = true
        return clientMessageID
    }

    /// Cancel gagal: stop bisa ditekan lagi. Respons untuk pertanyaan lama tidak mengubah pertanyaan baru.
    mutating func stopCanceling(clientMessageID: String) {
        guard self.clientMessageID == clientMessageID else { return }
        isCanceling = false
    }

    mutating func start(clientMessageID: String) {
        self = ChatTurn(clientMessageID: clientMessageID)
    }

    /// Ack gateway diterima. Seq yang tidak terbaca = turn berikutnya mana pun dianggap penutupnya.
    mutating func accept(questionSeq seq: Int?, for clientMessageID: String) {
        guard self.clientMessageID == clientMessageID else { return }
        let questionSeq = seq ?? .min
        self.questionSeq = questionSeq
        if let latestEndSeq, latestEndSeq > questionSeq {
            self = ChatTurn()
        }
    }

    /// Event `turn_end`; tanpa `id` dianggap milik turn terbaru.
    mutating func end(seq: Int?) {
        guard isAwaiting else { return }
        let seq = seq ?? .max
        latestEndSeq = max(latestEndSeq ?? seq, seq)
        if let questionSeq, seq > questionSeq {
            self = ChatTurn()
        }
    }

    /// Kirim pertanyaan ini ditolak; penolakan pertanyaan lama tidak membuka kunci pertanyaan baru.
    mutating func cancel(clientMessageID: String) {
        guard self.clientMessageID == clientMessageID else { return }
        self = ChatTurn()
    }

    /// Percakapan berganti: pertanyaan apa pun tidak lagi ditunggu.
    mutating func cancel() {
        self = ChatTurn()
    }
}
