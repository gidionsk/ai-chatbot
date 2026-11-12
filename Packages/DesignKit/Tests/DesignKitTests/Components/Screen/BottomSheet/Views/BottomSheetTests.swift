//
//  BottomSheetTests.swift
//  DesignKitTests
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Wadah hanya menambah grabber dan jarak safe area bawah; tinggi dan lebar sisanya milik isi dan layar.
@MainActor
struct BottomSheetTests {
    private let width: CGFloat = 375
    private let rowHeight: CGFloat = 44

    @Test(arguments: [CGFloat.zero, 34])
    func theSheetHugsItsContentAndClearsTheBottomSafeArea(bottomInset: CGFloat) {
        let size = size(of: sheet(rows: 3, bottomInset: bottomInset))
        #expect(abs(size.width - width) <= 0.5)
        #expect(abs(size.height - handleHeight - 3 * rowHeight - bottomInset) <= 0.5)
    }

    @Test
    func tallerContentMakesATallerSheet() {
        let short = size(of: sheet(rows: 2, bottomInset: .zero))
        let tall = size(of: sheet(rows: 5, bottomInset: .zero))
        #expect(abs(tall.height - short.height - 3 * rowHeight) <= 0.5)
    }
}

// MARK: - Helpers

private extension BottomSheetTests {
    /// Grabber beserta jarak di atas dan di bawahnya.
    var handleHeight: CGFloat {
        CustomSizes.BottomSheet.handleHeight.scaledToArtwork + FigmaSize.spacingMedium.scaledToArtwork
            + FigmaSize.spacingLarge.scaledToArtwork
    }

    func sheet(rows: Int, bottomInset: CGFloat) -> some View {
        BottomSheet(
            closeLabel: "Tutup",
            bottomInset: bottomInset,
            onClose: {},
            content: {
                ForEach(0..<rows, id: \.self) { _ in Color.clear.frame(height: rowHeight) }
            }
        )
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
