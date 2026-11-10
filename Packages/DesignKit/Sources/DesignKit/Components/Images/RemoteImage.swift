//
//  RemoteImage.swift
//  DesignKit
//
//  Created by Wendra on 27/10/26.
//

import Kingfisher
import SwiftUI

/// Gambar dari URL lewat Kingfisher (cache memori + disk, validasi status HTTP, batal saat view hilang).
/// Pembungkus tipis agar pemakai DesignKit tidak meng-import Kingfisher langsung.
/// `placeholder` tampil selama mengunduh; `fallback` tampil bila URL kosong/tidak valid atau unduhan gagal.
/// `pointSize` adalah sisi terpanjang ukuran tampil; gambar di-downsample ke ukuran itu × skala layar.
@MainActor
public struct RemoteImage<Placeholder: View, Fallback: View>: View {
    @Environment(\.displayScale)
    private var displayScale
    private let url: URL?
    private let pointSize: CGFloat
    private let placeholder: Placeholder
    private let fallback: Fallback

    public init(
        url: URL?, pointSize: CGFloat, @ViewBuilder placeholder: () -> Placeholder,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.url = url
        self.pointSize = pointSize
        self.placeholder = placeholder()
        self.fallback = fallback()
    }

    public var body: some View {
        KFImage(url)
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: pointSize, height: pointSize)))
            .scaleFactor(displayScale)
            .placeholder { placeholder }
            .onFailureView { fallback }
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFit()
    }
}
