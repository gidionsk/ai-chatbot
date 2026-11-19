//
//  ReferenceLetterDemoForm.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterDemoForm: View {
    @Environment(\.designColors) private var colors
    @EnvironmentObject private var demo: ReferenceLetterDemoState

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(ReferenceLetterDemoData.inquiry.introduction)
                .designFont(.body)
                .foregroundColor(colors.colorsTextPrimaryDark)
                .fixedSize(horizontal: false, vertical: true)
            form
            if demo.isValidated {
                Text(ReferenceLetterDemoData.validated)
                    .designFont(.caption)
                    .foregroundColor(colors.colorsTextPositive)
            }
        }
        .onChange(of: demo.form.values) { _ in
            if demo.isValidated { demo.isValidated = false }
        }
    }

    private var form: some View {
        IntentFormView<ReferenceLetterDemoField>(
            state: $demo.form,
            title: ReferenceLetterDemoData.title,
            confirmLabel: ReferenceLetterDemoData.confirm,
            cancelLabel: ReferenceLetterDemoData.cancel,
            presentation: ReferenceLetterDemoData.presentation,
            selectionSummary: ReferenceLetterDemoData.selectionSummary,
            onOpenChoices: { demo.activeField = $0 },
            onConfirm: { demo.isValidated = true },
            onCancel: {
                demo.isValidated = false
                demo.activeField = nil
            }
        )
    }
}
