//
//  View+ScrollBottom.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI

public extension View {
    /// Apply to the scroll content, after its padding. Name the containing ScrollView with the same space.
    /// Melaporkan apakah ujung konten berjarak paling jauh `distance` dari bawah viewport. Hanya perubahan yang
    /// dilaporkan, jadi scroll panjang tidak me-render ulang pemakai.
    @MainActor
    func onScrollBottomChange<Space: Hashable>(
        in coordinateSpace: Space, viewportHeight: CGFloat, distance: CGFloat, perform: @escaping (Bool) -> Void
    ) -> some View {
        background {
            GeometryReader { geometry in
                let isNearBottom = geometry.frame(in: .named(coordinateSpace)).maxY - viewportHeight <= distance
                Color.clear
                    .onAppear { perform(isNearBottom) }
                    .onChange(of: isNearBottom, perform: perform)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
