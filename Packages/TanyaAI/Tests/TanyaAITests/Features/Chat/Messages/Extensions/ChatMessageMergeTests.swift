//
//  ChatMessageMergeTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Testing

@testable import TanyaAI

/// Merge history/SSE: cek pesan yang sudah ada dulu, baru tambahkan sisanya; tidak menumpuk duplikat.
struct ChatMessageMergeTests {
    @Test
    func historyNewestFirstBecomesChronological() {
        #expect([].merging(messages([5, 3, 4])).map(\.seq) == [3, 4, 5])
    }

    @Test
    func overlappingHistoryAddsOnlyTheRemainder() {
        let merged = messages([1, 2, 3]).merging(messages([5, 4, 3, 2]))
        #expect(merged.map(\.seq) == [1, 2, 3, 4, 5])
        #expect(Set(merged.map(\.id)).count == merged.count)
    }

    @Test
    func sameMessageIdReplacesTheStoredCopyInPlace() {
        let tombstone = ChatMessage(id: "m-2", seq: 2, author: .customer, text: "pesan 2", status: .canceled)
        let merged = messages([1, 2, 3]).merging([tombstone])
        #expect(merged.map(\.seq) == [1, 2, 3])
        #expect(merged[1].status == .canceled)
    }

    @Test
    func newerStreamMessageAppendsAndOlderOneIsSortedIn() {
        #expect(messages([1, 2]).merging(messages([4])).map(\.seq) == [1, 2, 4])
        #expect(messages([1, 4]).merging(messages([2])).map(\.seq) == [1, 2, 4])
    }

    @Test
    func latestSeqIsTheHighestNotTheLast() {
        #expect(messages([3, 9, 4]).latestSeq == 9)
        #expect([ChatMessage]().latestSeq == nil)
    }
}

// MARK: - Helpers

private extension ChatMessageMergeTests {
    func messages(_ seqs: [Int]) -> [ChatMessage] {
        seqs.map { ChatMessage(id: "m-\($0)", seq: $0, author: .bot, text: "pesan \($0)", status: .active) }
    }
}
