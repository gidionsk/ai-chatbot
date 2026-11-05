//
//  ChatQuestionTopKey.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI

/// Tepi atas pertanyaan terbaru. Nil selama barisnya belum dibuat `LazyVStack`.
struct ChatQuestionTopKey: PreferenceKey {
    static let defaultValue: Anchor<CGPoint>? = nil

    static func reduce(value: inout Anchor<CGPoint>?, nextValue: () -> Anchor<CGPoint>?) {
        value = value ?? nextValue()
    }
}
