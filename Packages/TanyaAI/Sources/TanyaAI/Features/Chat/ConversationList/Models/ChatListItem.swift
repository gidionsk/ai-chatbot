//
//  ChatListItem.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import CoreGraphics
import DesignKit

/// Satu baris table percakapan. `isSpaced` memberi jarak dari baris percakapan di atasnya.
enum ChatListItem: Identifiable, Equatable {
    case welcome(isEnabled: Bool)
    case date(ChatDayIdentifier, isSpaced: Bool)
    case message(ChatRow, isSpaced: Bool)
    case followUps([String], isEnabled: Bool)
    /// Kartu status live agent (antre, selesai, batal, tidak tersedia). `isLeaveEnabled` hanya dipakai kartu antre,
    /// yang membawa tombol batal di dalam kartunya.
    case liveAgentNotice(LiveAgentNotice, isLeaveEnabled: Bool)
    case agentTyping
    /// "Mencari customer assistant..." selama antre setelah sapaan otomatis agen.
    case agentSearching
    /// Loading di bawah pertanyaan yang belum dijawab bot.
    case answerLoading
    /// Konten yang disisipkan pemakai `ChatScreen`.
    case content

    var id: ChatListItemID {
        switch self {
        case .welcome:
            return .welcome
        case .date(let day, _):
            return .date(day)
        case .message(let row, _):
            return .message(row.id)
        case .followUps:
            return .followUps
        case .liveAgentNotice(let notice, _):
            return .liveAgentNotice(notice.seq)
        case .agentTyping:
            return .agentTyping
        case .agentSearching:
            return .agentSearching
        case .answerLoading:
            return .answerLoading
        case .content:
            return .content
        }
    }

    var isQuestion: Bool {
        guard case .message(let row, _) = self else { return false }
        return row.isQuestion
    }

    /// Jarak dari tepi atas baris ke isinya; posisi parkir pertanyaan dihitung dari isinya, bukan dari tepi baris.
    /// Tanpa `default`: baris baru wajib memilih jaraknya di sini.
    var topSpacing: CGFloat {
        switch self {
        case .date(_, isSpaced: true), .message(_, isSpaced: true), .liveAgentNotice, .agentTyping, .agentSearching,
            .answerLoading:
            return FigmaSize.spacingLarge.scaledToArtwork
        case .date(_, isSpaced: false), .message(_, isSpaced: false), .welcome, .followUps, .content:
            return .zero
        }
    }
}
