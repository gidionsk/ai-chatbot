//
//  CardStyle.swift
//  DesignKit
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI

/// Permukaan kartu standar: isi `colorsSurfacePrimary`, sudut membulat, dan garis tepi tipis bila `isOutlined`.
/// Bayangan bila `isElevated`; tanpa garis tepi, kartu hanya terangkat oleh bayangan (seperti CardView Android).
/// Hanya latar; padding isi tetap milik komponen pemakai.
struct CardStyle: ViewModifier {
    @Environment(\.designColors)
    private var colors
    let isOutlined: Bool
    let isElevated: Bool
    let cornerRadius: CGFloat
    let outlineColor: Color

    func body(content: Content) -> some View {
        content.background(surface)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }

    private var surface: some View {
        fill.overlay(shape.strokeBorder(outline, lineWidth: FigmaSize.weightOutline.scaledToArtwork))
    }

    @ViewBuilder
    private var fill: some View {
        if isElevated {
            shape.fill(colors.colorsSurfacePrimary).designShadow()
        } else {
            shape.fill(colors.colorsSurfacePrimary)
        }
    }

    private var outline: Color {
        isOutlined ? outlineColor : .clear
    }
}
