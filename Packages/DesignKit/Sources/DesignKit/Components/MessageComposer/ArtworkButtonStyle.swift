//
//  ArtworkButtonStyle.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Menampilkan ikon berwarna utuh apa adanya. Berbeda dengan `.plain`, status disabled tidak meredupkan ikon,
/// karena aset nonaktif (`send-off`) sudah membawa warnanya sendiri; tap dan aksesibilitas tetap dikunci `Button`.
struct ArtworkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
