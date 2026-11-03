//
//  ChatDateFormatTests.swift
//  TanyaAI
//
//  Created by Wendra on 3/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Pola Figma "14 Oct 2026" untuk semua bahasa; hanya nama bulan yang mengikuti bahasa fitur.
@MainActor
struct ChatDateFormatTests {
    @Test(arguments: [("id", "14 Okt 2026"), ("en", "14 Oct 2026")])
    func dayFirstPatternFollowsFigma(identifier: String, expected: String) throws {
        let date = try #require(Date(wire: "2026-10-14T12:00:00Z"))
        #expect(ChatDateFormat.dayLabel(for: date, locale: Locale(identifier: identifier)) == expected)
    }
}
