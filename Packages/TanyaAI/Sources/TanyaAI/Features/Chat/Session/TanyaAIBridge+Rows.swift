//
//  TanyaAIBridge+Rows.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

extension TanyaAIBridge {
    func listItems(
        isEnabled: Bool,
        isWelcomeAvailable: Bool,
        isContentInjected: Bool
    ) -> [ChatListItem] {
        var items = [ChatListItem](rows: rows)
            .inserting(visibleLiveAgentNotices, isLeaveEnabled: isEnabled && !isLeavingAgent)
            .appendingAnswerLoading(isAwaitingReply: isAwaitingReply)
        if isWelcomeAvailable, isWelcomeVisible {
            items.insert(.welcome(isEnabled: isEnabled && isReady && !isAwaitingReply), at: .zero)
        }
        if isAgentTyping {
            items.append(.agentTyping)
        }
        if !followUps.isEmpty {
            items.append(.followUps(followUps, isEnabled: isEnabled && isReady && !isAwaitingReply))
        }
        if isContentInjected {
            items.append(.content)
        }
        return items
    }
}
