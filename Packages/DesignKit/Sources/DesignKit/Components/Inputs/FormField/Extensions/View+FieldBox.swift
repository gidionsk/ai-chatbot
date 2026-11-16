//
//  View+FieldBox.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

extension View {
    /// Kotak isi field form; lihat `FieldBox`.
    func fieldBox(isInvalid: Bool) -> some View {
        modifier(FieldBox(isInvalid: isInvalid))
    }
}
