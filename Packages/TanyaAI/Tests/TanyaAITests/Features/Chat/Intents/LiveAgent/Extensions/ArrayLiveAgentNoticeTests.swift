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
            messages.endedAgentSessions(isOngoing: true, closedBy: [])
                == [LiveAgentNotice(kind: .ended, seq: 4)])
        #expect(
            messages.endedAgentSessions(isOngoing: false, closedBy: [LiveAgentNotice(kind: .canceled, seq: 5)])
                == [LiveAgentNotice(kind: .ended, seq: 7)])
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
