//
//  OptionList.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Isi bottom sheet untuk memilih: judul, lalu daftar pilihan. `items` nil = daftar masih diambil pemakai (mis. dari
/// service host), jadi spinner yang tampil. `.single`: satu ketukan langsung memanggil `onSelect`. `.multiple`: centang
/// sebanyak yang diperlukan lalu tombol `confirmLabel`, yang menempel di tepi bawah sheet dan tidak ikut ter-scroll
/// (`bottomSheetFooter`). Tombol aktif bila ada centang yang masih ada di daftar;
/// `isEmptyAllowed` = pemakai boleh menerima hasil kosong (mengosongkan pilihan lama). `onSelect` menerima id pilihan
/// urut sesuai daftar; menutup sheet tetap tugas pemakai. Padding isi milik komponen ini, wadah sheet hanya memberi
/// permukaan. Di daftar panjang, pilihan pertama dari `selectedIDs` langsung terlihat saat sheet dibuka. Centang
/// sementara milik komponen ini; bila pemakai mengganti `selectedIDs` atau `mode` selagi daftar tampil, centang
/// mengikuti nilai baru itu.
/// TODO: Konfirmasi ukuran judul, baris, dan penanda dengan Figma; sementara dari foto.
@MainActor
public struct OptionList: View {
    @Environment(\.designColors) private var colors
    @State private var selection: OptionSelection
    /// Pilihan dari pemakai; perubahannya mengganti centang sementara.
    private let givenSelection: OptionSelection
    private let title: String
    private let items: [OptionItem]?
    private let confirmLabel: String
    private let isEmptyAllowed: Bool
    /// Pilihan yang digulir ke tengah sheet. Diambil dari `selectedIDs` pemakai, bukan centang sementara, supaya
    /// daftar tidak melompat selama nasabah mencentang.
    private let focusedID: String?
    private let onSelect: ([String]) -> Void

    public init(
        title: String,
        items: [OptionItem]?,
        selectedIDs: [String] = [],
        mode: OptionSelectionMode = .single,
        confirmLabel: String = String(),
        isEmptyAllowed: Bool = false,
        onSelect: @escaping ([String]) -> Void
    ) {
        let givenSelection = OptionSelection(mode: mode, selectedIDs: selectedIDs)
        _selection = State(initialValue: givenSelection)
        self.givenSelection = givenSelection
        self.title = title
        self.items = items
        self.confirmLabel = confirmLabel
        self.isEmptyAllowed = isEmptyAllowed
        self.focusedID = items?.map(\.id).first(where: givenSelection.isSelected)
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            heading
            rows
        }
        .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
        .padding(.bottom, listBottomPadding)
        .bottomSheetFooter { confirmButton }
        .onChange(of: givenSelection) { selection = $0 }
    }

    private var heading: some View {
        Text(title)
            .designFont(.title)
            .foregroundColor(colors.colorsTextPrimaryDark)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, FigmaSize.spacingMedium.scaledToArtwork)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var rows: some View {
        if let items {
            ForEach(items) { item in
                OptionRow(item: item, mode: selection.mode, isSelected: selection.isSelected(item.id)) {
                    select(item.id, in: items)
                }
                .id(rowID(of: item))
            }
        } else {
            LoadingIndicator()
                .frame(maxWidth: .infinity, minHeight: CustomSizes.OptionList.loadingHeight.scaledToArtwork)
        }
    }

    /// Hanya untuk pilihan banyak dan setelah daftar tersedia. Padding di semua sisi milik tombol ini, supaya selama
    /// menempel di bawah sheet baris yang di-scroll tidak menyentuhnya.
    @ViewBuilder
    private var confirmButton: some View {
        if isConfirming, let items {
            let isConfirmable = selection.isConfirmable(in: items, isEmptyAllowed: isEmptyAllowed)
            FilledButton(title: confirmLabel) {
                onSelect(selection.ordered(in: items))
            }
            .disabled(!isConfirmable)
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
        }
    }
}

// MARK: - Helpers

private extension OptionList {
    var isConfirming: Bool { selection.mode == .multiple && items != nil }

    /// Daftar tanpa tombol konfirmasi ditutup padding bawahnya sendiri; dengan tombol, jarak itu milik tombol.
    var listBottomPadding: CGFloat {
        guard isConfirming else { return FigmaSize.spacingLarge.scaledToArtwork }
        return .zero
    }

    /// Baris pilihan awal memakai penanda fokus sheet; baris lain tetap memakai id-nya sendiri.
    func rowID(of item: OptionItem) -> AnyHashable {
        guard item.id == focusedID else { return AnyHashable(item.id) }
        return AnyHashable(BottomSheetFocus.id)
    }
}

// MARK: - Actions

private extension OptionList {
    func select(_ id: String, in items: [OptionItem]) {
        guard selection.toggle(id) else { return }
        onSelect(selection.ordered(in: items))
    }
}
