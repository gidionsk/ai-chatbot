//
//  View+Surface.swift
//  DesignKit
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI

public extension View {
    /// Kartu standar (isi, radius, bayangan, garis tepi). Pakai ini daripada menyusun ulang di setiap view.
    /// `isOutlined: false` untuk kartu yang hanya memakai bayangan, misalnya `ActionCard`; `isElevated: false`
    /// untuk permukaan rata, misalnya `DateChip`. `cornerRadius` sudah di-scale oleh pemakai.
    func cardStyle(
        isOutlined: Bool = true, isElevated: Bool = true,
        cornerRadius: CGFloat = CustomSizes.Card.cornerRadius.scaledToArtwork,
        outlineColor: Color = CustomColors.Stroke.color
    ) -> some View {
        modifier(
            CardStyle(
                isOutlined: isOutlined, isElevated: isElevated, cornerRadius: cornerRadius, outlineColor: outlineColor
            )
        )
    }

    /// Bayangan standar untuk permukaan yang mengambang.
    func designShadow() -> some View {
        modifier(DesignShadow())
    }
}
