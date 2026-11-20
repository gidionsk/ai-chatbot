//
//  LeaveAgentConfirmationModifier.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import DesignKit
import SwiftUI

/// Konfirmasi End Session di bottom sheet DesignKit (Figma node 1903-8266): Yes memanggil `leave-agent`, No hanya
/// menutup sheet. Dipasang di root halaman supaya latar gelap sheet menutupi header dan composer. Sheet ikut tertutup
/// bila bar sesi agen hilang selama terbuka (sesi selesai, antrean ditutup, atau percakapan berganti), supaya Yes
/// tidak mengakhiri antrean atau sesi berikutnya.
@MainActor
struct LeaveAgentConfirmationModifier: ViewModifier {
    @Environment(\.locale) private var locale
    @Binding private var isPresented: Bool
    /// Bar sesi agen masih tampil.
    private let isAvailable: Bool
    private let onConfirm: () -> Void

    init(isPresented: Binding<Bool>, isAvailable: Bool, onConfirm: @escaping () -> Void) {
        _isPresented = isPresented
        self.isAvailable = isAvailable
        self.onConfirm = onConfirm
    }

    func body(content: Content) -> some View {
        content
            .bottomSheet(isPresented: $isPresented, closeLabel: String(ChatCopy.sheetClose, locale: locale)) {
                ConfirmationPrompt(
                    title: String(ChatCopy.leaveAgentConfirmTitle, locale: locale),
                    message: String(ChatCopy.leaveAgentConfirmMessage, locale: locale),
                    confirmTitle: String(ChatCopy.leaveAgentConfirm, locale: locale),
                    cancelTitle: String(ChatCopy.leaveAgentCancel, locale: locale),
                    onConfirm: confirm,
                    onCancel: close
                )
            }
            .onChange(of: isAvailable) { isStillAvailable in
                guard !isStillAvailable else { return }
                close()
            }
    }
}

// MARK: - Helpers

private extension LeaveAgentConfirmationModifier {
    func confirm() {
        isPresented = false
        onConfirm()
    }

    func close() {
        isPresented = false
    }
}
