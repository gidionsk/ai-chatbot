//
//  ArrayLiveAgentNoticeTests.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Posisi kartu live agent di daftar dan kartu selesai dari history.
struct ArrayLiveAgentNoticeTests {
    /// Kartu tepat setelah pesan terakhir yang lebih awal, jadi tetap di hari pesan itu; tombol batal hanya aktif di
    /// kartu antre dan ada di dalam kartunya, bukan baris sendiri. Pertanyaan lokal yang belum di-ack tetap di bawah
    /// kartu.
    @Test
    func noticesFollowTheLastEarlierMessage() {
        let firstDay = ChatDayIdentifier(date: Date(timeIntervalSince1970: .zero))
        let secondDay = ChatDayIdentifier(date: Date(timeIntervalSince1970: 86_400))
        let pending = LocalQuestion(id: "q", text: "Halo", afterSeq: 2)
        let items: [ChatListItem] = [
            .date(firstDay, isSpaced: false), .message(.message(message(seq: 2)), isSpaced: true),
            .date(secondDay, isSpaced: true), .message(.message(message(seq: 6)), isSpaced: true),
            .message(.local(pending), isSpaced: true)
        ]
        let notices = [LiveAgentNotice(kind: .canceled, seq: 4), LiveAgentNotice(kind: .connecting, seq: 7)]
        let inserted = items.inserting(notices, isLeaveEnabled: true)
        #expect(
            inserted.map(\.id) == [
                .date(firstDay), .message("m-2"), .liveAgentNotice(4), .date(secondDay), .message("m-6"),
                .liveAgentNotice(7), .message("q")
            ])
        #expect(inserted[2] == .liveAgentNotice(notices[0], isLeaveEnabled: false))
        #expect(inserted[5] == .liveAgentNotice(notices[1], isLeaveEnabled: true))
    }

    @Test
    func noticeBeforeEveryMessageGoesFirst() {
        let items: [ChatListItem] = [.message(.message(message(seq: 9)), isSpaced: false)]
        let ids = items.inserting([LiveAgentNotice(kind: .ended, seq: 3)], isLeaveEnabled: true).map(\.id)
        #expect(ids == [.liveAgentNotice(3), .message("m-9")])
    }

    /// Sesi dimulai di pesan agen pertama setelah bot menjawab: kartu "Connected" di posisi event antre sesi itu bila
    /// ada dari stream, selain itu tepat setelah pesan sebelumnya atau di awal daftar.
    @Test
    func agentSessionIsConnectedAtItsQueueEventOrBeforeItsFirstAgentMessage() {
        let messages = [
            message(seq: 1, author: .assistant), message(seq: 4, author: .agent), message(seq: 5, author: .user),
            message(seq: 6, author: .agent), message(seq: 7, author: .assistant), message(seq: 9, author: .user),
            message(seq: 11, author: .agent)
        ]
        #expect(messages.connectedAgentSessions(streamNotices: []) == [connected(1), connected(9)])
        #expect(messages.connectedAgentSessions(streamNotices: [opener(3), opener(8)]) == [connected(3), connected(8)])
        // Event antre sesi pertama bukan milik sesi berikutnya.
        #expect(messages.connectedAgentSessions(streamNotices: [opener(3)]) == [connected(3), connected(9)])
        #expect([message(seq: 2, author: .agent)].connectedAgentSessions(streamNotices: []) == [connected(.min)])
    }

    /// Event penutup memisahkan sesi, dan event antre yang sudah ditutup tidak menjadi posisi sesi berikutnya. Agen
    /// yang bergabung tanpa mengirim pesan tetap memulai sesi.
    @Test
    func closingEventsSplitSessionsAndRetireTheirQueueEvent() {
        let bot = message(seq: 1, author: .assistant)
        let canceled = LiveAgentNotice(kind: .canceled, seq: 4)
        let lateGreeting = [bot, message(seq: 9, author: .agent)]
        #expect(lateGreeting.connectedAgentSessions(streamNotices: [opener(3), canceled]) == [connected(1)])
        let greetings = [bot, message(seq: 3, author: .agent), message(seq: 7, author: .agent)]
        let timedOut = [opener(2), LiveAgentNotice(kind: .queueTimeout, seq: 4), opener(6)]
        #expect(greetings.connectedAgentSessions(streamNotices: timedOut) == [connected(2), connected(6)])
        let joined = LiveAgentNotice(kind: .joined, seq: 3)
        let ended = LiveAgentNotice(kind: .ended, seq: 4)
        #expect([bot].connectedAgentSessions(streamNotices: [opener(2), joined, ended]) == [connected(2)])
        #expect([bot].connectedAgentSessions(streamNotices: [joined]) == [connected(3)])
    }

    /// Sesi berakhir saat bot menjawab lagi; kartu setelah pesan agen terakhir sesi itu.
    @Test
    func agentSessionEndsWhenTheAssistantAnswersAgain() {
        let messages = [
            message(seq: 1, author: .assistant), message(seq: 2, author: .agent), message(seq: 3, author: .user),
            message(seq: 4, author: .agent), message(seq: 5, author: .user), message(seq: 6, author: .assistant),
            message(seq: 7, author: .agent)
        ]
        #expect(
            ended(in: messages, isOngoing: true)
                == [LiveAgentNotice(kind: .ended, seq: 4)])
        #expect(
            ended(in: messages, isOngoing: false, closedBy: [LiveAgentNotice(kind: .canceled, seq: 5)])
                == [LiveAgentNotice(kind: .ended, seq: 7)])
    }

    /// Posisi akhir sesi dari event `state` menggantikan tebakan pesan agen terakhir, jadi pesan nasabah selama sesi
    /// tetap di atas kartu. Posisi di luar rentang sesi tidak dipakai; posisi sama dengan pesan dibaca setelahnya.
    @Test
    func endedCardUsesTheStateExitOfItsSession() {
        let messages = [
            message(seq: 2, author: .agent), message(seq: 3, author: .user), message(seq: 5, author: .assistant),
            message(seq: 6, author: .agent), message(seq: 7, author: .user)
        ]
        let card = { LiveAgentNotice(kind: .ended, seq: $0) }
        #expect(ended(in: messages, isOngoing: false, exitSeqs: [4, 8]) == [card(4), card(8)])
        #expect(ended(in: messages, isOngoing: false, exitSeqs: [8]) == [card(2), card(8)])
        #expect(ended(in: messages, isOngoing: false, exitSeqs: [7]) == [card(2), card(7)])
    }

    /// Event keluar menutup sesi yang dibuka `agent_joined` tanpa pesan agen, dan sesi berikutnya yang dimulai tanpa
    /// jawaban bot di antaranya tidak menghapus kartu sesi sebelumnya.
    @Test
    func exitClosesEverySessionItBounds() {
        let card = { LiveAgentNotice(kind: .ended, seq: $0) }
        let joinedOnly = [message(seq: 2, author: .assistant), message(seq: 4, author: .user)]
        #expect(ended(in: joinedOnly, isOngoing: false, joinedSeqs: [3], exitSeqs: [5]) == [card(5)])
        #expect(ended(in: joinedOnly, isOngoing: true, joinedSeqs: [3]).isEmpty)

        let back = [message(seq: 2, author: .agent), message(seq: 3, author: .user), message(seq: 6, author: .agent)]
        #expect(ended(in: back, isOngoing: true, exitSeqs: [4]) == [card(4)])
        #expect(ended(in: back, isOngoing: false, exitSeqs: [4, 7]) == [card(4), card(7)])
    }

    /// Kartu penutup spesifik dari stream tetap diutamakan walau datang setelah event keluar.
    @Test
    func specificClosingCardWinsOverTheExit() {
        let messages = [message(seq: 2, author: .agent), message(seq: 3, author: .user)]
        let canceled = LiveAgentNotice(kind: .canceled, seq: 5)
        #expect(ended(in: messages, isOngoing: false, closedBy: [canceled], exitSeqs: [4]).isEmpty)
    }

    /// Antrean baru setelah event keluar menutup sesi sebelumnya, jadi kartu batal antrean itu tidak menghapus kartu
    /// selesai sesi sebelumnya.
    @Test
    func nextQueueClosesThePreviousSession() {
        let messages = [message(seq: 2, author: .agent), message(seq: 3, author: .user)]
        let canceled = LiveAgentNotice(kind: .canceled, seq: 6)
        let queue: [AgentSessionMark] = [.queued(seq: 5), .exit(seq: 7, isServed: false)]
        #expect(
            ended(in: messages, isOngoing: false, closedBy: [canceled], exitSeqs: [4], marks: queue)
                == [LiveAgentNotice(kind: .ended, seq: 4)])
    }

    /// Keluar dari `AGENT_ACTIVE` tanpa pesan agen atau `agent_joined` tetap sesi dengan agen; keluar dari antre saja
    /// bukan. Kartu penutup sebelum jawaban bot terakhir milik sesi lain.
    @Test
    func servedExitWithoutAnOpenerStillEnds() {
        let messages = [message(seq: 2, author: .assistant), message(seq: 3, author: .user)]
        let card = LiveAgentNotice(kind: .ended, seq: 5)
        let olderClosing = LiveAgentNotice(kind: .ended, seq: 1)
        let ownClosing = LiveAgentNotice(kind: .ended, seq: 4)
        #expect(ended(in: messages, isOngoing: false, closedBy: [olderClosing], exitSeqs: [5]) == [card])
        #expect(ended(in: messages, isOngoing: false, closedBy: [ownClosing], exitSeqs: [5]).isEmpty)
        #expect(ended(in: messages, isOngoing: false, marks: [.exit(seq: 5, isServed: false)]).isEmpty)
    }

    /// Posisi tunggu `leave-agent` bukan batas sesi: pesan agen sesudahnya (mis. dari history setelah reconnect yang
    /// melewatkan event `state`) memindahkan kartu ke bawahnya, tetap satu kartu. Event keluar sesi yang sama
    /// menggantikannya; event keluar setelah jawaban bot milik sesi berikutnya.
    @Test
    func leavingPositionDoesNotSplitTheSession() {
        let messages = [
            message(seq: 4, author: .agent), message(seq: 6, author: .agent), message(seq: 8, author: .user),
            message(seq: 9, author: .assistant)
        ]
        let leaving = AgentSessionMark.leaving(seq: 5, isServed: true)
        let card = { LiveAgentNotice(kind: .ended, seq: $0) }
        #expect(ended(in: messages, isOngoing: false, marks: [leaving]) == [card(6)])
        #expect(ended(in: Array(messages.prefix(1)), isOngoing: false, marks: [leaving]) == [card(5)])
        let exit = AgentSessionMark.exit(seq: 7, isServed: true)
        #expect(ended(in: Array(messages.prefix(2)), isOngoing: false, marks: [leaving, exit]) == [card(7)])
        #expect(
            ended(in: messages, isOngoing: false, marks: [leaving, .exit(seq: 12, isServed: true)]) == [
                card(6), card(12)
            ])
    }

    /// Event antre dan bergabung yang tiba setelah posisi tunggu (replay pembuka sesi yang aktif saat init) masih sesi
    /// yang sama; antrean baru setelah jawaban bot tidak.
    @Test
    func replayedOpenerAfterLeavingStaysInTheSession() {
        let card = { LiveAgentNotice(kind: .ended, seq: $0) }
        let leaving = AgentSessionMark.leaving(seq: 2, isServed: true)
        let replay: [AgentSessionMark] = [leaving, .queued(seq: 3), .joined(seq: 4), .exit(seq: 7, isServed: true)]
        #expect(ended(in: [message(seq: 2, author: .user)], isOngoing: false, marks: replay) == [card(7)])
        let nextQueue = [message(seq: 2, author: .user), message(seq: 3)]
        let queued: [AgentSessionMark] = [leaving, .queued(seq: 4)]
        #expect(ended(in: nextQueue, isOngoing: true, marks: queued) == [card(2)])
    }

    /// Kartu dari history memakai `seq` pesan yang ditutupnya dan tampil tepat setelah pesan itu, bukan sebelumnya.
    @Test
    func historyNoticeFollowsTheMessageItCloses() {
        let items: [ChatListItem] = [3, 4, 5].map { .message(.message(message(seq: $0)), isSpaced: false) }
        let ids = items.inserting([LiveAgentNotice(kind: .ended, seq: 4)], isLeaveEnabled: true).map(\.id)
        #expect(ids == [.message("m-3"), .message("m-4"), .liveAgentNotice(4), .message("m-5")])
    }

    /// Serah terima tanpa pesan agen sampai bot menjawab lagi, atau sampai akhir daftar bila sudah selesai.
    /// Serah terima yang diikuti pesan agen memakai kartu selesai, bukan kartu ini.
    @Test
    func handoverWithoutAnAgentIsNotContinued() {
        let messages = [
            message(seq: 1, author: .user), message(seq: 2, intent: .liveAgent), message(seq: 4, author: .user),
            message(seq: 5), message(seq: 6, intent: .liveAgent), message(seq: 7, author: .agent),
            message(seq: 8, intent: .liveAgent)
        ]
        let notContinued = { LiveAgentNotice(kind: .notContinued, seq: $0) }
        #expect(messages.unfinishedHandovers(isSettled: true, closedBy: []) == [notContinued(2), notContinued(8)])
        #expect(messages.unfinishedHandovers(isSettled: false, closedBy: []) == [notContinued(2)])
        let canceled = LiveAgentNotice(kind: .canceled, seq: 3)
        #expect(messages.unfinishedHandovers(isSettled: true, closedBy: [canceled]) == [notContinued(8)])
    }
}

// MARK: - Helpers

private extension ArrayLiveAgentNoticeTests {
    func ended(
        in messages: [ChatMessage],
        isOngoing: Bool,
        closedBy notices: [LiveAgentNotice] = [],
        joinedSeqs: [Int] = [],
        exitSeqs: [Int] = [],
        marks: [AgentSessionMark] = []
    ) -> [LiveAgentNotice] {
        let joined = joinedSeqs.map(AgentSessionMark.joined)
        let served = exitSeqs.map { AgentSessionMark.exit(seq: $0, isServed: true) }
        return messages.endedAgentSessions(isOngoing: isOngoing, closedBy: notices, marks: joined + served + marks)
    }

    func connected(_ seq: Int) -> LiveAgentNotice {
        LiveAgentNotice(kind: .connected, seq: seq)
    }

    func opener(_ seq: Int) -> LiveAgentNotice {
        LiveAgentNotice(kind: .connecting, seq: seq)
    }

    func message(seq: Int, author: ChatAuthor = .assistant, intent: ChatIntent? = nil) -> ChatMessage {
        ChatMessage(id: "m-\(seq)", seq: seq, author: author, text: "pesan \(seq)", status: .active, intent: intent)
    }
}
