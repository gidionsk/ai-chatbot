//
//  MessageBubbleShape.swift
//  DesignKit
//
//  Created by Wendra on 28/10/26.
//

import SwiftUI
import UIKit

/// Bubble pesan keluar (Figma): tiga sudut membulat, sudut kanan bawah siku sebagai penunjuk pengirim.
/// iOS 15 belum punya `UnevenRoundedRectangle`, jadi path dibuat lewat `UIBezierPath`.
struct MessageBubbleShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        // UIBezierPath sudah membatasi radius ke setengah sisi terpendek (bubble satu baris tetap rapi).
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, .bottomLeft],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}
