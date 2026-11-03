//
//  Image+DesignColorIcon.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

public extension Image {
    /// Ikon berwarna DesignKit dari bundle package, bukan bundle host.
    init(_ icon: DesignColorIcon) {
        self.init(icon.rawValue, bundle: .module)
    }
}

public extension UIImage {
    /// Versi UIKit dari `Image(_:)`; nil bila imageset tidak ada di bundle.
    convenience init?(_ icon: DesignColorIcon) {
        self.init(named: icon.rawValue, in: .module, with: nil)
    }
}
