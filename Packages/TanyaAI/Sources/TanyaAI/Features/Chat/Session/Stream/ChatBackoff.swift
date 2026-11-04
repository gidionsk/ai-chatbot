//
//  ChatBackoff.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Jeda sebelum menyambung ulang: 1, 2, 4, … detik, maksimal 30, tanpa batas percobaan selama halaman
/// terbuka. Kembali ke 1 detik setelah stream sempat tersambung. Metadata kebijakan, bukan ukuran desain.
struct ChatBackoff {
    private static let initialDelay: TimeInterval = 1
    private static let maximumDelay: TimeInterval = 30
    private static let growth: Double = 2
    private static let millisecondsPerSecond: Double = 1_000
    private static let nanosecondsPerSecond: Double = 1_000_000_000
    private static let unauthorizedStatus = 401
    /// 404 `conversation_not_found` dan 410 `conversation_closed`.
    private static let conversationGoneStatuses: Set<Int> = [404, 410]
    private static let serverErrorStatus = 500

    private var failures = 0

    /// Jeda produksi; test menyuntikkan jeda instan.
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * nanosecondsPerSecond))
    }

    /// Sesi OMNI habis: berhenti dan serahkan ke host (login ulang), bukan di-retry.
    static func isUnauthorized(statusCode: Int) -> Bool {
        statusCode == unauthorizedStatus
    }

    /// Percakapan tidak ada lagi atau sudah ditutup/diarsipkan: halaman tidak bisa lanjut.
    static func isConversationGone(statusCode: Int) -> Bool {
        conversationGoneStatuses.contains(statusCode)
    }

    /// Dipakai bila body bukan error envelope: hanya error server yang di-retry.
    static func isServerError(statusCode: Int) -> Bool {
        statusCode >= serverErrorStatus
    }

    mutating func reset() {
        failures = 0
    }

    /// Jeda berikutnya. `retryAfterMilliseconds` dari server (`retry_after_ms` pada 429/503) didahulukan.
    mutating func nextDelay(retryAfterMilliseconds: Int? = nil) -> TimeInterval {
        let exponent = Double(failures)
        failures += 1
        if let retryAfterMilliseconds {
            return TimeInterval(retryAfterMilliseconds) / Self.millisecondsPerSecond
        }
        return min(Self.initialDelay * pow(Self.growth, exponent), Self.maximumDelay)
    }
}
