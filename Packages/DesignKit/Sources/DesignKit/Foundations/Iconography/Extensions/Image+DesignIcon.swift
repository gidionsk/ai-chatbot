//
//  Image+DesignIcon.swift
//  DesignKit
//
//  Created by Wendra on 27/10/26.
//

import SwiftUI

public extension Image {
    /// Ikon DesignKit dari bundle package, bukan bundle host.
    init(_ icon: DesignIcon) {
        self.init(icon.rawValue, bundle: .module)
    }
}

public extension UIImage {
    /// Versi UIKit dari `Image(_:)`; nil bila imageset tidak ada di bundle.
    convenience init?(_ icon: DesignIcon) {
        self.init(named: icon.rawValue, in: .module, with: nil)
    }
}
