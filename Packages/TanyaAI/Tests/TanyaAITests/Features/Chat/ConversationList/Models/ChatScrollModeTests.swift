//
//  ChatScrollModeTests.swift
//  TanyaAITests
//
//  Created by Wendra on 11/11/26.
//

import Testing

@testable import TanyaAI

/// Mode posisi daftar: apa yang berubah saat nasabah menggeser, dan kapan ruang kosong parkir masih disediakan.
struct ChatScrollModeTests {
    @Test
    func draggingReleasesAHeldQuestionButKeepsItsSpace() {
        #expect(ChatScrollMode.holdingQuestion.afterDrag == .releasedQuestion)
        #expect(ChatScrollMode.releasedQuestion.afterDrag == .releasedQuestion)
    }

    @Test
    func draggingCancelsFollowingTheLatest() {
        #expect(ChatScrollMode.followingLatest.afterDrag == .free)
        #expect(ChatScrollMode.free.afterDrag == .free)
    }

    @Test
    func onlyQuestionModesKeepTheTrailingSpace() {
        #expect(ChatScrollMode.holdingQuestion.isQuestionParked)
        #expect(ChatScrollMode.releasedQuestion.isQuestionParked)
        #expect(!ChatScrollMode.free.isQuestionParked)
        #expect(!ChatScrollMode.followingLatest.isQuestionParked)
    }
}
