//
//  ChatIntent.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `intent` hasil router gateway pada pesan bot (§4). Intent baru ditambah sebagai case saat ada yang membacanya;
/// nilai lain dibaca sebagai `unknown`, bukan gagal decode.
enum ChatIntent: String, Sendable {
    /// Pesan bot "Baik, kami akan menghubungkan…" saat percakapan diserahkan ke agen (`source` kosong).
    /// State antre/agen tetap diatur event `state` dan `system`, bukan intent ini.
    case handoverToAgent = "handover-to-agent"
    case unknown

    /// Nil bila `intent` tidak ada atau kosong (pesan nasabah, agen, dan jawaban tanpa intent).
    init?(wire: String?) {
        guard let wire, !wire.isEmpty else { return nil }
        self = Self(rawValue: wire) ?? .unknown
    }
}
