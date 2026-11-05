//
//  ScreenViewport+ChatParking.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import CoreGraphics
import DesignKit

extension ScreenViewport {
    /// Jarak tepi atas viewport ke pertanyaan yang parkir: di bawah header, menyisakan preview jawaban sebelumnya.
    var chatParkingOffset: CGFloat {
        headerHeight + FigmaSize.spacingDoubleExtraLarge.scaledToArtwork
    }
}
