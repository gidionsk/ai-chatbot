//
//  MessageBubbleShapeTests.swift
//  DesignKit
//
//  Created by Wendra on 28/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

/// Hanya sudut kanan bawah yang siku; tiga sudut lain membulat.
struct MessageBubbleShapeTests {
    @Test
    func onlyTheBottomTrailingCornerIsSquare() {
        let rect = CGRect(x: 0, y: 0, width: 120, height: 40)
        let path = MessageBubbleShape(cornerRadius: 16).path(in: rect)
        #expect(path.contains(CGPoint(x: rect.maxX - 0.5, y: rect.maxY - 0.5)))
        #expect(!path.contains(CGPoint(x: rect.maxX - 0.5, y: rect.minY + 0.5)))
        #expect(!path.contains(CGPoint(x: rect.minX + 0.5, y: rect.minY + 0.5)))
        #expect(!path.contains(CGPoint(x: rect.minX + 0.5, y: rect.maxY - 0.5)))
    }
}
