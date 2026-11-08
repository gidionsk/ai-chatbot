//
//  Date+Wire.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

extension Date {
    private static let wireFormatter = ISO8601DateFormatter()
    private static let fractionalWireFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// `created_at` gateway: ISO 8601 dengan zona waktu, dengan atau tanpa pecahan detik.
    init?(wire: String) {
        guard let date = Self.wireFormatter.date(from: wire) ?? Self.fractionalWireFormatter.date(from: wire) else {
            return nil
        }
        self = date
    }
}
