//
//  CGFloat+Artwork.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import UIKit

public extension CGFloat {
    /// Rumus host tanpa batas atas: round(nilai / (lebar referensi / lebar layar)).
    var scaledToArtwork: CGFloat {
        scaledToArtwork(ratio: ArtworkScale.currentRatio)
    }
}

extension CGFloat {
    func scaledToArtwork(ratio: CGFloat) -> CGFloat {
        guard isFinite, ratio.isFinite, ratio > .zero else {
            return .zero
        }
        let scaled = self / ratio
        return scaled.isFinite ? scaled.rounded() : .zero
    }
}
