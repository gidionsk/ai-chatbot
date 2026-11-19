//
//  ReferenceLetterDemoSheetPresenter.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import DesignKit
import SwiftUI

/// Pasang sekali di root ChatScreen, bukan pada LiveAgentMessageRow.
@MainActor
struct ReferenceLetterDemoSheetPresenter: ViewModifier {
    @ObservedObject var demo: ReferenceLetterDemoState

    func body(content: Content) -> some View {
        content
            .environmentObject(demo)
            .bottomSheet(item: $demo.activeField, closeLabel: ReferenceLetterDemoData.close) { field in
                IntentFormOptions<ReferenceLetterDemoField>(
                    state: $demo.form,
                    fieldID: field,
                    title: ReferenceLetterDemoData.presentation(for: field).label,
                    confirmLabel: ReferenceLetterDemoData.choose,
                    onSelect: { demo.activeField = nil }
                )
            }
    }
}
