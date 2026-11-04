//
//  TanyaAIRepository.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

import TanyaAI

/// Data yang sudah diolah `TanyaAIUseCase` untuk ditampilkan; dibaca ViewModel.
struct TanyaAIRepository {
    /// Nil = halaman tanpa sambutan; package tidak menampilkan sambutan berisi teks kosong.
    var welcome: WelcomeContent?
}
