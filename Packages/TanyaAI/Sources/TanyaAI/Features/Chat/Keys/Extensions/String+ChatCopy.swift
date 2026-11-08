//
//  String+ChatCopy.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import DesignKit
import Foundation

extension String {
    /// Copy Tanya AI dari bundle package sesuai locale host.
    init(_ copy: ChatCopy, locale: Locale) {
        self.init(key: copy.rawValue, bundle: .module, locale: locale)
    }
}
