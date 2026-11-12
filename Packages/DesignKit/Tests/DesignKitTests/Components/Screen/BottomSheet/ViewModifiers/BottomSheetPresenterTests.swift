//
//  BottomSheetPresenterTests.swift
//  DesignKitTests
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Isi sheet hanya dibangun selama sheet tampil, dan halaman di bawahnya tetap dirender. Berurutan karena memakai
/// window.
@MainActor
@Suite(.serialized)
struct BottomSheetPresenterTests {
    @Test(arguments: [false, true])
    func theContentIsBuiltOnlyWhilePresented(isPresented: Bool) {
        var isContentBuilt = false
        var isPageBuilt = false
        let page = Color.clear
            .onAppear { isPageBuilt = true }
            .bottomSheet(isPresented: .constant(isPresented), closeLabel: "Tutup") {
                Color.clear.frame(height: 80).onAppear { isContentBuilt = true }
            }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = UIHostingController(rootView: page)
        window.makeKeyAndVisible()
        window.rootViewController?.view.layoutIfNeeded()
        defer { window.isHidden = true }
        #expect(isPageBuilt)
        #expect(isContentBuilt == isPresented)
    }
}
