//
//  Image+ChatImage.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import SwiftUI

extension Image {
    /// Gambar Tanya AI dari bundle package, bukan bundle host.
    init(_ image: ChatImage) { self.init(image.rawValue, bundle: .module) }
}
