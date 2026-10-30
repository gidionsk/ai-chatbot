//
//  ChatTurnPhase.swift
//  TanyaAI
//
//  Created by Wendra on 30/10/26.
//

/// Fase pertanyaan yang sedang berjalan, untuk tombol composer.
enum ChatTurnPhase: Equatable {
    /// Tidak menunggu apa pun; bisa kirim.
    case idle
    /// Sejak kirim sampai pertanyaan nasabah datang dari stream (bubble tampil); input dikunci.
    case sending
    /// Pertanyaan sudah tampil, jawaban bot belum selesai; tombol menjadi stop.
    case awaitingReply
    /// Stop sudah ditekan; menunggu respons cancel atau `turn_end`.
    case canceling
}
