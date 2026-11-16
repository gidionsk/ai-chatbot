//
//  IntentFormPresenter.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

/// Satu pemasangan sheet di root chat. State keypad tidak hidup dalam sel table.
@MainActor
struct IntentFormPresenter: ViewModifier {
    @Environment(\.locale) private var locale
    let sessions: [String: ReferenceLetterSession]
    @Binding var sheet: IntentFormSheet?
    @State private var previousSheet: IntentFormSheet?
    @State private var isProcessing = false
    let onPresented: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .bottomSheet(
                item: $sheet,
                closeLabel: String(ChatCopy.referenceClose, locale: locale),
                isDismissable: !isProcessing
            ) { item in
                sheetContent(item)
            }
            .onChange(of: sheet, perform: didChangeSheet)
            .onChange(of: Set(sessions.keys)) { _ in
                if let sheet, sessions[sheet.instanceID] == nil { self.sheet = nil }
            }
            .onDisappear {
                sessions.values.forEach { $0.leaveScreen() }
                sheet = nil
                isProcessing = false
                onPresented(false)
            }
    }

    @ViewBuilder
    private func sheetContent(_ item: IntentFormSheet) -> some View {
        if let session = sessions[item.instanceID] {
            switch item {
            case .referenceOptions(_, let field):
                if let inquiry = session.inquiry {
                    ReferenceLetterOptions(inquiry: inquiry, draft: $session.draft, field: field) {
                        session.clearResolvedErrors()
                        sheet = nil
                    }
                }
            case .referencePIN:
                ReferenceLetterPINSheet(
                    session: session,
                    onClose: { if sheet == item { sheet = nil } },
                    onProcessing: { if sheet == item { isProcessing = $0 } }
                )
            }
        }
    }
}

// MARK: - Actions

private extension IntentFormPresenter {
    func didChangeSheet(_ value: IntentFormSheet?) {
        if case .referencePIN(let id)? = previousSheet, value != previousSheet {
            sessions[id]?.dismissPIN()
        }
        previousSheet = value
        if value == nil { isProcessing = false }
        onPresented(value != nil)
    }
}
