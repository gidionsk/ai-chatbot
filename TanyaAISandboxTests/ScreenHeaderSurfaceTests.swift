//
//  ScreenHeaderSurfaceTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 22/10/26.
//

import DesignKit
import SwiftUI
import Testing
import UIKit

extension HostWindowTests {
    /// Diuji di app host karena warna piksel hanya bisa dibaca dari window dengan scene sungguhan.
    @MainActor
    struct ScreenHeaderSurfaceTests {
        @Test
        func headerIsTransparentAtRestAndOpaqueWithFadeWhenFullyScrolled() throws {
            let height = ScreenHeader.height(isNotched: true)
            let fade = FigmaSize.spacingLarge.scaledToArtwork
            let reach = CustomSizes.Shadow.radius.scaledToArtwork + CustomSizes.Shadow.offsetY.scaledToArtwork
            let atRest = try render(scrollProgress: .zero)
            let scrolled = try render(scrollProgress: 1)
            // Titik di padding kiri header, jauh dari tombol back dan judul; y dihitung dari tepi atas layar.
            let inHeader = height / 2
            let inFade = height + fade / 2
            let beyond = height + max(fade, reach * 2) + 4

            #expect(isBackdrop(try atRest.pixel(atHeaderOffset: inHeader)), "header harus transparan saat diam")
            #expect(isBackdrop(try atRest.pixel(atHeaderOffset: inFade)), "tidak ada fade saat diam")
            #expect(isSurface(try scrolled.pixel(atHeaderOffset: inHeader)), "header harus putih saat digulir")
            let fadePixel = try scrolled.pixel(atHeaderOffset: inFade)
            #expect(!(isBackdrop(fadePixel) || isSurface(fadePixel)), "gradient harus di antara putih dan latar")
            #expect(isBackdrop(try scrolled.pixel(atHeaderOffset: beyond)), "fade dan bayangan tidak menjalar")
        }

        /// Di atas latar putih fade tidak terlihat, jadi yang menggelapkan tepi bawah header hanya bayangan.
        @Test
        func shadowStaysVisibleOverTheFadeWhenScrolled() throws {
            let inShadow = ScreenHeader.height(isNotched: true) + CustomSizes.Shadow.offsetY.scaledToArtwork
            let atRest = try render(scrollProgress: .zero, backdrop: .white)
            let scrolled = try render(scrollProgress: 1, backdrop: .white)
            let middle = scrolled.width / 2
            let resting = try atRest.pixel(atHeaderOffset: inShadow, column: middle)
            let shadow = try scrolled.pixel(atHeaderOffset: inShadow, column: middle)
            #expect(isSurface(resting), "tanpa bayangan saat diam: \(resting)")
            #expect(shadow[1] < 250, "bayangan harus tergambar di atas gradient: \(shadow)")
        }

        /// Di tengah transisi surface setengah tembus: warnanya di antara latar dan putih, bukan salah satunya.
        @Test
        func headerBlendsWithTheBackdropMidwayThroughTheTransition() throws {
            let inHeader = ScreenHeader.height(isNotched: true) / 2
            let quarter = try render(scrollProgress: 0.25).pixel(atHeaderOffset: inHeader)
            let half = try render(scrollProgress: 0.5).pixel(atHeaderOffset: inHeader)
            #expect(!(isBackdrop(half) || isSurface(half)), "setengah jalan harus campuran: \(half)")
            // Latar merah: makin jauh digulir, kanal hijau makin mendekati putih.
            #expect(quarter[1] < half[1], "opacity harus naik sebanding progres: \(quarter) \(half)")
        }
    }
}

// MARK: - Helpers

private struct RenderedHeader {
    let image: CGImage
    let scale: CGFloat
    let headerTop: CGFloat

    var width: CGFloat { CGFloat(image.width) / scale }

    func pixel(atHeaderOffset offset: CGFloat, column: CGFloat = 2) throws -> [UInt8] {
        let point = CGRect(x: column * scale, y: (headerTop + offset) * scale, width: 1, height: 1)
        let crop = try #require(image.cropping(to: point.integral))
        var data = [UInt8](repeating: .zero, count: 4)
        let context = try #require(
            CGContext(
                data: &data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return data
    }
}

private extension HostWindowTests.ScreenHeaderSurfaceTests {
    /// Header di atas latar (default merah), seperti header di atas gambar latar chat.
    func render(scrollProgress: CGFloat, backdrop: Color = Color(red: 1, green: 0, blue: 0)) throws -> RenderedHeader {
        let content = ZStack(alignment: .top) {
            backdrop.ignoresSafeArea()
            ScreenHeader(title: "Judul", backLabel: "Back", scrollProgress: scrollProgress, isNotched: true, onBack: {})
        }
        .ignoresSafeArea(.container, edges: .top)
        let fixture = try HostWindowFixture(content)
        defer { fixture.close() }
        let window = try #require(fixture.controller.view.window)
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        #expect(ScreenHeader.isNotched(safeAreaTop: window.safeAreaInsets.top), "simulator test harus ber-notch")
        return RenderedHeader(image: try #require(image.cgImage), scale: image.scale, headerTop: .zero)
    }

    func isBackdrop(_ rgba: [UInt8]) -> Bool {
        rgba[0] > 240 && rgba[1] < 15 && rgba[2] < 15
    }

    func isSurface(_ rgba: [UInt8]) -> Bool {
        rgba[0] > 240 && rgba[1] > 240 && rgba[2] > 240
    }
}
