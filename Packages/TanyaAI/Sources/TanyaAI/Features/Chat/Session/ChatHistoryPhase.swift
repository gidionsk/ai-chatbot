//
//  ChatHistoryPhase.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

/// Hasil pembukaan halaman: menentukan apakah daftar perlu dibuka di pesan terbaru.
enum ChatHistoryPhase: Equatable {
    case loading
    /// Percakapan kosong; konten tetap di posisi teratas.
    case empty
    case restored
}
