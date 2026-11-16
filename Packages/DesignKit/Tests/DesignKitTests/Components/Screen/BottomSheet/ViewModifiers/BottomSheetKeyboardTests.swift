//
//  BottomSheetKeyboardTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Keyboard yang muncul selama sheet tampil mendorong sheet ke atasnya; keyboard yang sudah ada sebelum sheet dibuka
/// (mis. dari composer halaman) tidak. Berurutan karena memakai window.
@MainActor
@Suite(.serialized)
struct BottomSheetKeyboardTests {
    private let screen = CGRect(x: 0, y: 0, width: 375, height: 812)
    private let keyboardTop: CGFloat = 512

    @Test
    func theSheetSitsAboveAKeyboardOpenedWhileItIsPresented() async {
        var bottom = CGFloat.zero
        let host = UIHostingController(rootView: page(isPresented: true) { bottom = $0.maxY })
        let window = UIWindow(frame: screen)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await waitUntil { abs(bottom - screen.maxY) <= 0.5 }
        postKeyboardChange(top: keyboardTop)
        await waitUntil { abs(bottom - keyboardTop) <= 0.5 }
        postKeyboardChange(top: screen.maxY)
        await waitUntil { abs(bottom - screen.maxY) <= 0.5 }
    }

    @Test
    func aKeyboardOpenedBeforeTheSheetDoesNotLiftIt() async {
        var bottoms: [CGFloat] = []
        let host = UIHostingController(rootView: page(isPresented: false) { bottoms.append($0.maxY) })
        let window = UIWindow(frame: screen)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        postKeyboardChange(top: keyboardTop)
        host.rootView = page(isPresented: true) { bottoms.append($0.maxY) }
        await waitUntil { bottoms.contains { abs($0 - screen.maxY) <= 0.5 } }
        #expect(!bottoms.contains { abs($0 - keyboardTop) <= 0.5 })
    }

    @Test
    func theKeyboardTopIsReadFromTheNotification() {
        let frame = CGRect(x: 0, y: keyboardTop, width: 375, height: 300)
        let info: [AnyHashable: Any] = [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        let change = Notification(name: UIResponder.keyboardWillChangeFrameNotification, userInfo: info)
        #expect(change.keyboardTop == keyboardTop)
        #expect(Notification(name: UIResponder.keyboardWillChangeFrameNotification).keyboardTop == nil)
    }
}

// MARK: - Helpers

private extension BottomSheetKeyboardTests {
    /// Isi 80 pt; `onFrame` menerima frame isi itu di koordinat layar setiap kali berubah.
    func page(isPresented: Bool, onFrame: @escaping (CGRect) -> Void) -> some View {
        Color.clear.bottomSheet(isPresented: .constant(isPresented), closeLabel: "Tutup") {
            Color.clear.frame(height: 80).background(FrameProbe(onChange: onFrame))
        }
    }

    /// Sama dengan yang dikirim UIKit: frame akhir keyboard dibungkus `NSValue`.
    func postKeyboardChange(top: CGFloat) {
        let frame = CGRect(x: 0, y: top, width: screen.width, height: screen.maxY - top)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        )
    }
}
