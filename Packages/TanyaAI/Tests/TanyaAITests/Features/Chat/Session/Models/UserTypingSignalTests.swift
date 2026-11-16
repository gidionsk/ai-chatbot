//
//  UserTypingSignalTests.swift
//  TanyaAI
//
//  Created by Wendra on 14/11/26.
//

import Testing

@testable import TanyaAI

/// Antrean sinyal mengetik nasabah: yang menunggu digabung menjadi yang terbaru, `false` hanya dikirim setelah
/// `true`, dan sinyal dibuang bila tidak ada lagi yang menerimanya.
struct UserTypingSignalTests {
    @Test
    func aQueuedSignalIsTakenOnce() {
        var signal = UserTypingSignal()
        signal.queue(true)
        #expect(signal.isTyping)
        #expect(signal.takeNext(isDeliverable: true) == true)
        #expect(signal.takeNext(isDeliverable: true) == nil)
        #expect(signal.isTyping, "yang terakhir terkirim tetap dianggap sedang mengetik")
    }

    @Test
    func waitingSignalsCollapseIntoTheLatest() {
        var signal = UserTypingSignal()
        signal.queue(true)
        signal.queue(false)
        #expect(!signal.isTyping)
        #expect(signal.takeNext(isDeliverable: true) == nil, "false tanpa true yang terkirim tidak dikirim")
    }

    @Test
    func stoppingIsSentAfterTypingWasDelivered() {
        var signal = UserTypingSignal()
        signal.queue(true)
        _ = signal.takeNext(isDeliverable: true)
        signal.queue(false)
        #expect(signal.takeNext(isDeliverable: true) == false)
        #expect(!signal.isTyping)
    }

    @Test
    func typingIsRefreshedWithTheSameValue() {
        var signal = UserTypingSignal()
        signal.queue(true)
        _ = signal.takeNext(isDeliverable: true)
        signal.queue(true)
        #expect(signal.takeNext(isDeliverable: true) == true)
    }

    @Test
    func anUndeliverableSignalIsDropped() {
        var signal = UserTypingSignal()
        signal.queue(true)
        #expect(signal.takeNext(isDeliverable: false) == nil)
        #expect(!signal.isTyping)
        #expect(signal.takeNext(isDeliverable: true) == nil, "sinyal yang dibuang tidak dikirim belakangan")
    }
}
