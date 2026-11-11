//
//  ChatTableState.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import Foundation

/// Yang ditampilkan table dan pemicu posisi scroll-nya.
struct ChatTableState: Equatable {
    var items: [ChatListItem] = []
    /// Berubah setiap nasabah mengirim pertanyaan dari halaman ini.
    var sentQuestionID: String?
    /// Berubah setiap pesan baru datang di luar turn yang sedang berjalan, kartu live agent datang, atau agen mulai
    /// dan berhenti mengetik.
    var incomingMessageID: String?
    /// Berubah setiap nasabah menekan tombol ke pesan terbaru.
    var latestJumpID: UUID?
    var historyPhase = ChatHistoryPhase.loading
    var rowInputs = ChatRowInputs()
}
