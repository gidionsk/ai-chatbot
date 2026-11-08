//
//  DesignShadow.swift
//  DesignKit
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI

/// Bayangan standar untuk permukaan yang mengambang, misalnya kartu dan composer.
struct DesignShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(
            color: CustomColors.Shadow.color, radius: CustomSizes.Shadow.radius.scaledToArtwork,
            y: CustomSizes.Shadow.offsetY.scaledToArtwork
        )
    }
}
