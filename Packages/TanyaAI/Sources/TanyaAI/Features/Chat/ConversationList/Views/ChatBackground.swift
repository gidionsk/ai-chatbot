//
//  ChatBackground.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import SwiftUI

/// Latar halaman chat: gambar menempel di atas layar selebar layar; bagian bawah yang tidak tertutup gambar memakai
/// warna surface. Sengaja `scaledToFit`, bukan `scaledToFill` + `clipped`: di iOS 17 kombinasi itu membuat latar dan
/// isi scroll hilang (putih) selama swipe back interaktif di host.
struct ChatBackground: View {
    var body: some View {
        Image(ChatImage.chatBackground).resizable()
            .scaledToFit()
            .frame(maxHeight: .infinity, alignment: .top)
    }
}
