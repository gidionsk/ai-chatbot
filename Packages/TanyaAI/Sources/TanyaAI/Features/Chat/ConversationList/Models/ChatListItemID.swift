//
//  ChatListItemID.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

/// Identitas baris table. Pesan memakai id-nya sendiri; baris lain hanya ada satu per daftar, kecuali chip tanggal
/// dan kartu live agent.
enum ChatListItemID: Hashable {
    case welcome
    case date(ChatDayIdentifier)
    case message(String)
    case followUps
    /// Kartu live agent; `seq` event-nya (kartu dari history memakai seq pesan agen, yang tidak pernah sama).
    case liveAgentNotice(Int)
    case leaveAgentQueue
    case agentTyping
    case content
}
