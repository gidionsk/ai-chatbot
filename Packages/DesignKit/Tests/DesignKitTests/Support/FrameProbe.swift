//
//  FrameProbe.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

/// Dipasang sebagai `background`: melaporkan frame view itu di koordinat layar, saat tampil dan setiap kali berubah.
struct FrameProbe: View {
    let onChange: (CGRect) -> Void

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { onChange(proxy.frame(in: .global)) }
                .onChange(of: proxy.frame(in: .global), perform: onChange)
        }
    }
}
