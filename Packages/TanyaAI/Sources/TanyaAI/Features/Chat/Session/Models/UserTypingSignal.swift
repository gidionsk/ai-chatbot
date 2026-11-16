//
//  UserTypingSignal.swift
//  TanyaAI
//
//  Created by Wendra on 14/11/26.
//

/// Sinyal "nasabah sedang mengetik" ke agen (contract §7.7). Dikirim satu per satu secara berurutan, jadi `false`
/// tidak mendahului `true`; sinyal yang datang selama kiriman berjalan digabung menjadi yang terbaru, dan `false`
/// tanpa `true` yang pernah terkirim tidak dikirim. Kembali ke nilai awal = lupakan semuanya tanpa kiriman.
struct UserTypingSignal: Equatable {
    /// Sinyal terbaru yang belum dikirim; nil = tidak ada yang menunggu.
    private var isTypingQueued: Bool?
    /// Nilai terakhir yang dikirim ke server.
    private var isTypingDelivered = false

    /// Nilai terbaru yang diminta: yang masih menunggu, atau yang terakhir terkirim.
    var isTyping: Bool { isTypingQueued ?? isTypingDelivered }

    /// Sinyal baru menggantikan yang masih menunggu.
    mutating func queue(_ isTyping: Bool) {
        isTypingQueued = isTyping
    }

    /// Sinyal berikutnya untuk dikirim, dan antrean dikosongkan. Nil bila tidak ada yang menunggu, tidak ada lagi
    /// yang menerimanya (`isDeliverable` false), atau `false` padahal `true` belum pernah terkirim.
    mutating func takeNext(isDeliverable: Bool) -> Bool? {
        guard let isTyping = isTypingQueued else { return nil }
        isTypingQueued = nil
        guard isDeliverable, isTyping || isTypingDelivered else { return nil }
        isTypingDelivered = isTyping
        return isTyping
    }
}
