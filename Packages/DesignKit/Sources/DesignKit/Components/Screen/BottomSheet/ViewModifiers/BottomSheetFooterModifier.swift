//
//  BottomSheetFooterModifier.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

/// Menaruh `footer` di bawah isi. Di dalam bottom sheet, footer yang tampil adalah yang ditempel `BottomSheet` di tepi
/// bawahnya; salinan di sini tidak terlihat dan hanya memesan tempat setinggi footer, supaya tinggi sheet ikut
/// menghitungnya dan baris terakhir bisa digulir sampai di atas footer. Di luar sheet (mis. katalog), footer tampil
/// biasa di bawah isi. Footer yang ditempel digambar di luar isi, jadi status nonaktif dari pemakai (`.disabled` pada
/// isi) dibawa ikut bersamanya.
struct BottomSheetFooterModifier<Footer: View>: ViewModifier {
    @Environment(\.bottomSheetFooterPlacement) private var placement
    @Environment(\.isEnabled) private var isEnabled
    let footer: Footer

    func body(content: Content) -> some View {
        VStack(spacing: .zero) {
            content
            footer
                .opacity(isPinned ? .zero : CustomColors.opaque)
                .allowsHitTesting(!isPinned)
                .accessibilityHidden(isPinned)
        }
        .preference(key: BottomSheetFooterKey.self, value: pinnedFooter)
    }

    private var isPinned: Bool { placement == .pinned }

    private var pinnedFooter: AnyView? {
        guard isPinned else { return nil }
        return AnyView(footer.disabled(!isEnabled))
    }
}
