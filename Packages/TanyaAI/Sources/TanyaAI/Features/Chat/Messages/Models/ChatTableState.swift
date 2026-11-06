//
//  ChatTableState.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

/// Yang ditampilkan table dan pemicu posisi scroll-nya.
struct ChatTableState: Equatable {
    var items: [ChatListItem] = []
    /// Berubah setiap nasabah mengirim pertanyaan dari halaman ini.
    var sentQuestionID: String?
    /// Berubah setiap pesan baru datang di luar turn yang sedang berjalan.
    var incomingMessageID: String?
    var historyPhase = ChatHistoryPhase.loading
    var rowInputs = ChatRowInputs()
}
