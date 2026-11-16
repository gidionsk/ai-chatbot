//
//  CustomSizes.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import CoreGraphics

/// Dimensi desain (point pada artwork 375) yang belum ada di `FigmaSize`.
/// Setiap nilai di sini SELALU dipakai dengan `.scaledToArtwork`.
/// Cek `FigmaSize` dulu; minta tim desain menambah token agar nilai custom bisa dihapus.
/// Kelompok bersama dinamai per peran (`Header`, `Card`, `Shadow`); nilai milik satu komponen
/// memakai nama komponennya (`Composer`) supaya ikut terhapus bersama komponen itu.
public enum CustomSizes {
    /// Mengikuti navigation bar host (padding bawah 15, kiri-kanan 20). Padding atas dari tepi layar
    /// ada di `CustomScreenInsets` karena tidak di-scale.
    public enum Header {
        public static let bottomPadding: CGFloat = 15
        public static let horizontalPadding: CGFloat = 20
    }

    public enum Card {
        public static let cornerRadius: CGFloat = 8
    }

    public enum Chip {
        public static let cornerRadius: CGFloat = 16
        public static let suggestionCornerRadius: CGFloat = 20
    }

    /// Gambar bulat di atas sapaan halaman sambutan; 60 disesuaikan user di Byon (28 Oktober 2026).
    /// TODO: Konfirmasi dengan nilai Figma final.
    public enum Emblem {
        public static let size: CGFloat = 60
    }

    public enum Shadow {
        public static let radius: CGFloat = 10
        public static let offsetY: CGFloat = 2
    }

    /// Bubble pesan nasabah: radius tiga sudut (kanan bawah siku) dan jarak minimum dari tepi kiri.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari screenshot (sama dengan PR #36).
    public enum MessageBubble {
        public static let cornerRadius: CGFloat = 16
        public static let outgoingLeadingInset: CGFloat = 48
    }

    public enum Composer {
        public static let sendButton: CGFloat = 24
    }

    /// Perkiraan awal tinggi baris table sebelum terukur; bukan nilai Figma dan tidak terlihat di layar.
    public enum HostedTable {
        public static let estimatedRowHeight: CGFloat = 80
        /// Table menganggap tinggi 0 sebagai belum terukur dan memakai tinggi bawaan. Pecahan bisa membulat ke 0 lewat
        /// `scaledToArtwork`, jadi nilainya 1; baris kosong tetap tidak terlihat karena sel transparan.
        public static let minimumRowHeight: CGFloat = 1
    }

    /// Garis quote, radius code block, dan lebar kolom penanda list (hanging indent) pada `MarkdownContent`.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari screenshot.
    public enum Markdown {
        public static let quoteBarWidth: CGFloat = 3
        public static let cornerRadius: CGFloat = 8
        public static let listMarkerWidth: CGFloat = 8
        public static let imageHeight: CGFloat = 200
        public static let imageMaxSide: CGFloat = 335
    }

    /// Wadah bottom sheet: radius sudut atas, ukuran grabber, jarak geser ke bawah yang menutup sheet saat dilepas,
    /// dan jarak tambahan dari status bar pada layar tanpa notch.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari foto.
    public enum BottomSheet {
        public static let cornerRadius: CGFloat = 20
        public static let handleWidth: CGFloat = 40
        public static let handleHeight: CGFloat = 4
        public static let dismissDistance: CGFloat = 80
        public static let classicTopGap: CGFloat = 16
    }

    /// Indikator pilihan (radio dan centang) dan area loading pada daftar pilihan di bottom sheet.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari foto.
    public enum OptionList {
        public static let indicator: CGFloat = 20
        public static let radioDotInset: CGFloat = 5
        public static let checkboxCornerRadius: CGFloat = 4
        public static let loadingHeight: CGFloat = 120
    }

    /// Jarak atas-bawah label tombol isi penuh, mis. Konfirmasi di form dan Pilih di daftar pilihan banyak.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari foto.
    public enum FilledButton {
        public static let verticalPadding: CGFloat = 12
    }

    /// Kotak ikon dan chevron bulat pada kartu aksi.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari screenshot.
    public enum ActionCard {
        public static let iconBox: CGFloat = 40
        public static let chevron: CGFloat = 20
    }
}
