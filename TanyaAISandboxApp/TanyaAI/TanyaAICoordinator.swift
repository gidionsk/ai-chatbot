//
//  TanyaAICoordinator.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI

/// Rute Tanya AI dengan pola coordinator host; tidak membuat view model.
@MainActor
struct TanyaAICoordinator: View {
    static let named = String(describing: TanyaAICoordinator.self)
    @Binding var selectionCoordinatorName: String?
    /// Hasil inquiry init dari output UseCase induk; nilai, bukan binding, karena dibaca sekali saat dibuka.
    let greeting: TanyaAIInitGreeting
    let shortcuts: [TanyaAIInitShortcut]

    var body: some View {
        NavigationLink(tag: Self.named, selection: $selectionCoordinatorName) {
            TanyaAIDestination(greeting: greeting, shortcuts: shortcuts, onBack: close)
        } label: {
            EmptyView()
        }
        .hidden()
    }
}

// MARK: - Actions

private extension TanyaAICoordinator {
    func close() {
        guard selectionCoordinatorName == Self.named else { return }
        selectionCoordinatorName = nil
    }
}
