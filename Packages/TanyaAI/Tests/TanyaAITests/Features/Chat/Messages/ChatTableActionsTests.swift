//
//  ChatTableActionsTests.swift
//  TanyaAITests
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import TanyaAI

/// Sel yang tampil tidak dibangun ulang saat host mengganti handler, jadi aksinya harus tetap sampai ke yang baru.
@MainActor
@Suite(.serialized)
struct ChatTableActionsTests {
    private let link = URL(fileURLWithPath: "/link")

    @Test
    func aShownRowCallsTheLatestHandlers() async {
        let model = ActionModel()
        let probe = ActionProbe()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = UIHostingController(rootView: ActionPage(model: model, probe: probe))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await waitUntil { probe.shownActions != nil }
        model.label = "After"
        await waitUntil {
            probe.shownActions?.onOpenLink(link)
            return probe.calls.last == "After"
        }
        probe.shownActions?.onSelectFollowUp("Pertanyaan")
        #expect(probe.calls.last == "After")
        #expect(probe.rowBuilds == 1)
    }
}

@MainActor
private final class ActionModel: ObservableObject {
    @Published var label = "Before"
}

private final class ActionProbe {
    var shownActions: ChatRowActions?
    var calls: [String] = []
    var rowBuilds = 0
}

private struct ActionPage: View {
    @ObservedObject var model: ActionModel
    let probe: ActionProbe

    var body: some View {
        ChatTable(
            state: ChatTableState(items: ChatTableFixture.history(count: 1), historyPhase: .empty),
            headerHeight: .zero, actions: actions, onScrollProgress: { _ in },
            row: { _, actions in ActionRow(actions: actions, probe: probe) }
        )
    }

    private var actions: ChatRowActions {
        ChatRowActions(
            onOpenLink: { [label = model.label, probe] _ in probe.calls.append(label) },
            onSelectFollowUp: { [label = model.label, probe] _ in probe.calls.append(label) }
        )
    }
}

private struct ActionRow: View {
    let actions: ChatRowActions
    let probe: ActionProbe

    var body: some View {
        Color.clear.frame(height: 40)
            .onAppear {
                probe.shownActions = actions
                probe.rowBuilds += 1
            }
    }
}
