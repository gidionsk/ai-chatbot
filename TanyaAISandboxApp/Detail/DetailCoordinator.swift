//
//  DetailCoordinator.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI

/// Rute halaman detail dengan pola NavigationLink + tag milik host; tidak membuat view model.
@MainActor
struct DetailCoordinator: View {
    static let named = String(describing: DetailCoordinator.self)
    @Binding var selectionCoordinatorName: String?

    var body: some View {
        NavigationLink(tag: Self.named, selection: $selectionCoordinatorName) {
            DetailDestination()
        } label: {
            EmptyView()
        }
        .hidden()
    }
}
