//
//  AssetTests.swift
//  DesignKit
//
//  Created by Wendra on 17/10/26.
//

import Testing
import UIKit

@testable import DesignKit

struct AssetTests {
    @Test(arguments: DesignIcon.allCases)
    func everyIconLoadsFromThePackageBundle(icon: DesignIcon) throws {
        let loaded = try #require(UIImage(icon), "\(icon)")
        #expect(loaded.size == CGSize(width: 24, height: 24))
        #expect(loaded.renderingMode == .alwaysTemplate)
    }

    /// Ikon berwarna tidak boleh di-tint, jadi render original.
    @Test(arguments: DesignColorIcon.allCases)
    func everyColorIconLoadsUntinted(icon: DesignColorIcon) throws {
        let loaded = try #require(UIImage(icon), "\(icon)")
        #expect(loaded.size == CGSize(width: 24, height: 24))
        #expect(loaded.renderingMode == .alwaysOriginal)
    }

    @Test
    func everyImagesetHasAnIconCase() throws {
        let names = try FileManager.default.contentsOfDirectory(atPath: Self.catalogSourcePath)
            .filter { $0.hasSuffix(".imageset") }
            .map { String($0.dropLast(".imageset".count)) }
        let cases = DesignIcon.allCases.map(\.rawValue) + DesignColorIcon.allCases.map(\.rawValue)
        #expect(names.count == cases.count)
        #expect(Set(names) == Set(cases))
    }
}

// MARK: - Helpers

private extension AssetTests {
    /// Asset catalog sumber; dibaca dari repo karena `.car` hasil compile tidak bisa didaftar namanya.
    static var catalogSourcePath: String {
        // Root package = bagian sebelum `/Tests/` terakhir: tetap benar walau file test dipindah folder atau
        // repo di-clone di dalam folder bernama `Tests`.
        let path = #filePath
        let testsRange = path.range(of: "/Tests/", options: .backwards)
        let packageRoot = testsRange.map { String(path[..<$0.lowerBound]) } ?? path
        return packageRoot + "/Sources/DesignKit/Resources/Assets.xcassets"
    }
}
