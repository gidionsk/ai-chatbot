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
    /// Kartu status live agent (antre, selesai, batal, tidak tersedia).
    case liveAgentNotice(LiveAgentNotice)
    /// "Batalkan proses ini" di bawah kartu antre.
    case leaveAgentQueue(isEnabled: Bool)
    case agentTyping
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
        case .liveAgentNotice(let notice):
            return .liveAgentNotice(notice.seq)
        case .leaveAgentQueue:
            return .leaveAgentQueue
        case .agentTyping:
            return .agentTyping
        case .content:
            return .content
        }
    }

    var isQuestion: Bool {
        guard case .message(let row, _) = self else { return false }
        return row.isQuestion
    }

    /// Jarak dari tepi atas baris ke isinya; posisi parkir pertanyaan dihitung dari isinya, bukan dari tepi baris.
    var topSpacing: CGFloat {
        switch self {
        case .date(_, isSpaced: true), .message(_, isSpaced: true), .liveAgentNotice, .agentTyping:
            return FigmaSize.spacingLarge.scaledToArtwork
        case .leaveAgentQueue:
            return FigmaSize.spacingMedium.scaledToArtwork
        default:
            return .zero
        }
    }
}
