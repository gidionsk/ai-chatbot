//
//  AgentSessionEndScan.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Pembaca berurutan untuk kartu selesai sesi agen (lihat `endedAgentSessions`). Sesi dibuka pesan agen atau
/// `agent_joined`, lalu ditutup event `state` keluar dari agen, jawaban bot berikutnya, antrean baru setelah event
/// keluar, atau akhir daftar. Kartunya di posisi event keluar bila ada; tanpa event itu (history) tepat setelah pesan
/// agen terakhir. Sesi yang punya kartu penutup dari stream (mis. `queue_canceled`, `agent_ended`) tidak diberi kartu
/// lagi.
struct AgentSessionEndScan {
    let closingNotices: [LiveAgentNotice]
    private(set) var cards: [LiveAgentNotice] = []
    /// `seq` pesan agen atau `agent_joined` terakhir sesi yang sedang dibaca; nil = tidak ada sesi.
    private var lastSessionSeq: Int?
    private var exitSeq: Int?
    /// `exitSeq` dari `leave-agent` yang event `state`-nya belum diterima: pesan agen sesudahnya masih sesi ini, jadi
    /// kartu bergeser ke bawah pesan agen terakhir, bukan membuka sesi kedua.
    private var isExitPending = false
    /// Akhir hal terakhir di luar sesi (jawaban bot, kartu selesai, awal antrean): awal sesi yang pembukanya tidak
    /// diterima, supaya kartu penutup sesi sebelumnya tidak dihitung milik sesi itu.
    private var floorSeq = Int.min

    init(closingNotices: [LiveAgentNotice]) {
        self.closingNotices = closingNotices
    }

    mutating func read(_ message: ChatMessage) {
        switch message.author {
        case .agent:
            open(at: message.seq)
        case .assistant:
            close(before: message.seq)
            floorSeq = message.seq
        case .user, .unknown:
            break
        }
    }

    mutating func read(_ mark: AgentSessionMark) {
        switch mark {
        case .joined(let seq):
            open(at: seq)
        case .queued(let seq):
            queue(at: seq)
        case .exit(let seq, let isServed):
            leave(at: seq, isServed: isServed, isPending: false)
        case .leaving(let seq, let isServed):
            leave(at: seq, isServed: isServed, isPending: true)
        }
    }

    /// Sesi terakhir ditutup bila sudah keluar dari agen, atau bila tidak sedang antre atau dilayani agen.
    mutating func finish(isOngoing: Bool) -> [LiveAgentNotice] {
        guard exitSeq != nil || !isOngoing else { return cards }
        close(before: .max)
        return cards
    }
}

private extension AgentSessionEndScan {
    /// Pesan agen atau `agent_joined` setelah event keluar memulai sesi baru tanpa harus menunggu jawaban bot.
    mutating func open(at seq: Int) {
        if exitSeq != nil, !isExitPending {
            close(before: seq)
        }
        lastSessionSeq = seq
    }

    /// Antrean baru setelah event keluar resmi: kartu penutup sesudahnya milik antrean itu, bukan sesi sebelumnya.
    /// Posisi tunggu `leave-agent` tidak ditutup di sini: event antre sesudahnya bisa replay pembuka sesi yang sama
    /// (tiba setelah `left:true`), sedangkan antrean baru di aplikasi didahului jawaban bot yang sudah menutup sesi.
    mutating func queue(at seq: Int) {
        guard exitSeq != nil, !isExitPending else { return }
        close(before: seq)
        floorSeq = seq
    }

    /// Keluar setelah posisi tunggu `leave-agent` di sesi yang sama menggantikan posisi itu. Keluar kedua lainnya
    /// menutup sesi sebelumnya lebih dulu. Keluar dari `AGENT_ACTIVE` tanpa sesi yang terbaca tetap sesi dengan agen,
    /// dimulai setelah `floorSeq`.
    mutating func leave(at seq: Int, isServed: Bool, isPending: Bool) {
        if exitSeq != nil, !isExitPending {
            close(before: seq)
        }
        if lastSessionSeq == nil, isServed {
            lastSessionSeq = floorSeq
        }
        guard lastSessionSeq != nil else { return }
        exitSeq = seq
        isExitPending = isPending
    }

    mutating func close(before boundary: Int) {
        guard let lastSeq = lastSessionSeq else { return }
        let position = exitSeq.map { isExitPending ? Swift.max($0, lastSeq) : $0 } ?? lastSeq
        lastSessionSeq = nil
        exitSeq = nil
        isExitPending = false
        floorSeq = Swift.max(floorSeq, position)
        guard !closingNotices.contains(where: { $0.seq > lastSeq && $0.seq < boundary }) else { return }
        cards.append(LiveAgentNotice(kind: .ended, seq: position))
    }
}
