//
//  DetailDestination.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI

/// Pemilik view model halaman detail dan rutenya sendiri ke Tanya AI.
/// `@StateObject` dibuat sekali saat halaman di-push dan dilepas saat di-pop.
@MainActor
struct DetailDestination: View {
    @StateObject private var viewModel = DetailScreenViewModel()
    @State private var destinationCoordinatorName: String?

    var body: some View {
        ZStack {
            if destinationCoordinatorName == TanyaAICoordinator.named {
                TanyaAICoordinator(
                    selectionCoordinatorName: $destinationCoordinatorName,
                    greeting: viewModel.entryUseCase.output.greeting,
                    shortcuts: viewModel.entryUseCase.output.shortcuts
                )
            }
            Screen {
                DetailScreen(viewModel: viewModel, onOpenTanyaAI: viewModel.openTanyaAI)
            }
        }
        .onAppear {
            viewModel.entryUseCase.callback.onStartTanyaAI = { destinationCoordinatorName = TanyaAICoordinator.named }
        }
    }
}
