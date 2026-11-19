//
//  ReferenceLetterDemoState.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI

/// State demo satu halaman, disimpan oleh ChatScreen di luar sel table.
@MainActor
final class ReferenceLetterDemoState: ObservableObject {
    @Published var form = IntentFormState<ReferenceLetterDemoField>(fields: ReferenceLetterDemoData.fields)
    @Published var activeField: ReferenceLetterDemoField?
    @Published var isValidated = false
}
