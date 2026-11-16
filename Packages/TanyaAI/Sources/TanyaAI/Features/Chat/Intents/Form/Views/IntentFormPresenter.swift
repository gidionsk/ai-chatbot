//
//  IntentFormPresenter.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

/// Satu pemasangan sheet pilihan di root chat. Flow PIN memakai presentasi existing host.
@MainActor
struct IntentFormPresenter: ViewModifier {
    @Environment(\.locale) private var locale
    @Binding var sheet: IntentFormSheet?
    let sessions: [String: ReferenceLetterSession]
    let onPresented: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .bottomSheet(
                item: $sheet,
                closeLabel: String(ChatCopy.referenceClose, locale: locale)
            ) { item in
                sheetContent(item)
            }
            .onChange(of: sheet) { onPresented($0 != nil) }
            .onChange(of: Set(sessions.keys)) { _ in
                if let sheet, sessions[sheet.instanceID] == nil { self.sheet = nil }
            }
            .onDisappear {
                sessions.values.forEach { $0.leaveScreen() }
                sheet = nil
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

            }
        }
    }
}
