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
    /// Kartu tepat setelah pesan terakhir yang lebih awal, jadi tetap di hari pesan itu; tombol batal di bawah kartu
    /// antre. Pertanyaan lokal yang belum di-ack tetap di bawah kartu.
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
        let ids = items.inserting(notices, isLeaveEnabled: false).map(\.id)
        #expect(
            ids == [
                .date(firstDay), .message("m-2"), .liveAgentNotice(4), .date(secondDay), .message("m-6"),
                .liveAgentNotice(7),
                .leaveAgentQueue, .message("q")
            ])
    }

    @Test
    func noticeBeforeEveryMessageGoesFirst() {
        let items: [ChatListItem] = [.message(.message(message(seq: 9)), isSpaced: false)]
        let ids = items.inserting([LiveAgentNotice(kind: .ended, seq: 3)], isLeaveEnabled: true).map(\.id)
        #expect(ids == [.liveAgentNotice(3), .message("m-9")])
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
}

// MARK: - Helpers

private extension ArrayLiveAgentNoticeTests {
    func message(seq: Int, author: ChatAuthor = .assistant) -> ChatMessage {
        ChatMessage(id: "m-\(seq)", seq: seq, author: author, text: "pesan \(seq)", status: .active)
    }
}
