//
//  AsyncWait.swift
//  DesignKit
//
//  Created by Wendra on 26/10/26.
//

import Foundation
import Testing

/// Menunggu kondisi dengan `Task.sleep`, bukan memutar RunLoop yang menahan update SwiftUI.
@MainActor
func waitUntil(
    timeout: TimeInterval = 3, sourceLocation: SourceLocation = #_sourceLocation, _ condition: () async -> Bool
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await condition() { return }
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
    Issue.record("Kondisi tidak terpenuhi dalam \(timeout) detik", sourceLocation: sourceLocation)
}
