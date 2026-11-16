//
//  Binding+Presence.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

extension Binding {
    /// Ada atau tidaknya nilai optional sebagai `Bool`, untuk presentasi berbasis nilai: true selama nilainya ada, dan
    /// diisi false = nilainya dikosongkan. Diisi true tidak mengubah apa pun, karena nilainya tidak diketahui.
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresent in
                guard !isPresent else { return }
                wrappedValue = nil
            }
        )
    }
}
