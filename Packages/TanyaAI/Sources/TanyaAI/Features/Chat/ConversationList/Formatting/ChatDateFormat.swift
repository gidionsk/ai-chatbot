//
//  ChatDateFormat.swift
//  TanyaAI
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Label chip tanggal dengan pola Figma "14 Oct 2026" untuk semua bahasa; nama bulan mengikuti bahasa fitur
/// (id "14 Okt 2026"). Zona waktu perangkat, sama dengan pengelompokan hari.
@MainActor
enum ChatDateFormat {
    private static let pattern = "d MMM yyyy"
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = pattern
        return formatter
    }()

    static func dayLabel(for date: Date, locale: Locale) -> String {
        formatter.locale = locale
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}
