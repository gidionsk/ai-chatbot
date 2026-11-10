//
//  ChatImageTests.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

import Foundation
import Testing
import UIKit

@testable import TanyaAI

struct ChatImageTests {
    @Test(arguments: ChatImage.allCases)
    func everyImageLoadsFromThePackageBundle(image: ChatImage) {
        #expect(UIImage(named: image.rawValue, in: .module, with: nil) != nil, "\(image)")
    }

    @Test
    func everyImagesetHasAnImageCase() throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: Self.catalogSourcePath)
            .filter { $0.hasSuffix(".imageset") }
            .map { String($0.dropLast(".imageset".count)) }
        #expect(Set(names) == Set(ChatImage.allCases.map(\.rawValue)))
    }
}

// MARK: - Helpers

private extension ChatImageTests {
    /// Asset catalog sumber; dibaca dari repo karena `.car` hasil compile tidak bisa didaftar namanya.
    static var catalogSourcePath: String {
        // Root package = bagian sebelum `/Tests/` terakhir: tetap benar walau file test dipindah folder atau
        // repo di-clone di dalam folder bernama `Tests`.
        let path = #filePath
        let testsRange = path.range(of: "/Tests/", options: .backwards)
        let packageRoot = testsRange.map { String(path[..<$0.lowerBound]) } ?? path
        return packageRoot + "/Sources/TanyaAI/Resources/Assets.xcassets"
    }
}
