//
//  ChatDayTests.swift
//  TanyaAITests
//
//  Created by Wendra on 3/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Chip tanggal di atas pesan pertama setiap hari kalender (zona waktu perangkat).
struct ChatDayTests {
    @Test
    func rowsSplitWhereTheLocalDayChanges() throws {
        let calendar = try jakartaCalendar()
        let days = [
            message(1, "2026-10-14T09:00:00+07:00"), message(2, "2026-10-14T23:59:00+07:00"),
            message(3, "2026-10-15T00:01:00+07:00")
        ].groupedByDay(calendar: calendar)
        #expect(days.map { $0.rows.map(\.id) } == [["m-1", "m-2"], ["m-3"]])
        #expect(days.map(\.date) == [day("2026-10-14T00:00:00+07:00"), day("2026-10-15T00:00:00+07:00")])
    }

    /// Hari mengikuti zona perangkat, bukan zona dari server: 23:30 WIB = keesokan hari di WITA.
    @Test
    func dayFollowsTheDeviceTimeZone() throws {
        var calendar = try jakartaCalendar()
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Makassar"))
        let days = [message(1, "2026-10-14T22:00:00+07:00"), message(2, "2026-10-14T23:30:00+07:00")]
            .groupedByDay(calendar: calendar)
        #expect(days.count == 2)
    }

    @Test
    func rowWithoutADateJoinsThePreviousDay() throws {
        let calendar = try jakartaCalendar()
        let days = [message(1, "2026-10-14T09:00:00+07:00"), message(2, nil)].groupedByDay(calendar: calendar)
        #expect(days.map { $0.rows.count } == [2])
        #expect([message(1, nil)].groupedByDay(calendar: calendar).first?.date == nil)
    }

    /// Jam perangkat bisa berbeda dengan server: hari yang mundur tidak memunculkan chip kedua untuk hari lama.
    @Test
    func earlierDayJoinsTheCurrentDay() throws {
        let calendar = try jakartaCalendar()
        let days = [
            message(1, "2026-10-14T09:00:00+07:00"), message(2, "2026-10-15T00:01:00+07:00"),
            message(3, "2026-10-14T23:59:00+07:00")
        ].groupedByDay(calendar: calendar)
        #expect(days.map { $0.rows.map(\.id) } == [["m-1"], ["m-2", "m-3"]])
        #expect(Set(days.map(\.id)).count == days.count)
    }

    /// Bubble lokal memakai waktu kirim; diganti salinan stream di hari yang sama, chip (id hari) tetap.
    @Test
    func localQuestionUsesItsSendTimeAndKeepsTheDayWhenReplaced() throws {
        let calendar = try jakartaCalendar()
        let sentAt = try #require(Date(wire: "2026-11-03T10:00:00+07:00"))
        let local = ChatRow.local(LocalQuestion(id: "q", text: "Beli USD", afterSeq: nil, sentAt: sentAt))
        let before = [local].groupedByDay(calendar: calendar)
        let after = [message(1, "2026-11-03T10:00:01+07:00")].groupedByDay(calendar: calendar)
        #expect(before.map(\.id) == after.map(\.id))
        #expect(before.first?.date == day("2026-11-03T00:00:00+07:00"))
    }

    /// Buffer di-append, kelompok dibentuk sekali per hari (bukan menyalin kelompok setiap baris).
    @Test
    func thousandsOfSameDayRowsStayInOneGroupInOrder() throws {
        let calendar = try jakartaCalendar()
        let rows = (1...5_000).map { message($0, "2026-10-14T09:00:00+07:00") }
        let days = rows.groupedByDay(calendar: calendar)
        #expect(days.count == 1)
        #expect(days.first?.rows == rows)
    }
}

// MARK: - Helpers

private extension ChatDayTests {
    func jakartaCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Jakarta"))
        return calendar
    }

    func day(_ text: String) -> Date? {
        Date(wire: text)
    }

    func message(_ seq: Int, _ createdAt: String?) -> ChatRow {
        .message(
            ChatMessage(
                id: "m-\(seq)", seq: seq, author: .customer, text: "pesan", status: .active,
                createdAt: createdAt.flatMap(Date.init(wire:))
            )
        )
    }
}
