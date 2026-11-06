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
    case welcome(isEnabled: Bool, isTermsVisible: Bool)
    case date(ChatDayID, isSpaced: Bool)
    case message(ChatRow, isSpaced: Bool)
    case followUps([String], isEnabled: Bool)
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
        case .date(_, isSpaced: true), .message(_, isSpaced: true):
            return FigmaSize.spacingLarge.scaledToArtwork
        default:
            return .zero
        }
    }
}
