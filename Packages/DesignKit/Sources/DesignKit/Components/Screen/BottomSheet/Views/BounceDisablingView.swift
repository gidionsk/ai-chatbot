//
//  BounceDisablingView.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import UIKit

/// View kosong yang mematikan bounce pada scroll view terdekat di atasnya, begitu ia masuk window. Hanya scroll view
/// itu yang berubah; scroll view lain di aplikasi tidak tersentuh. Class karena butuh `didMoveToWindow` milik UIKit.
final class BounceDisablingView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        let scrollView = sequence(first: superview, next: { $0?.superview })
            .compactMap { $0 as? UIScrollView }
            .first
        scrollView?.bounces = false
        scrollView?.alwaysBounceVertical = false
    }
}
