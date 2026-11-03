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

    /// Garis quote, radius code block/tabel, dan lebar kolom penanda list (hanging indent) pada `MarkdownContent`.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi.
    public enum Markdown {
        public static let quoteBarWidth: CGFloat = 3
        public static let cornerRadius: CGFloat = 8
        public static let listMarkerWidth: CGFloat = 16
    }

    /// Kotak ikon dan chevron bulat pada kartu aksi.
    /// TODO: Cocokkan dengan nilai Figma; sementara estimasi dari screenshot.
    public enum ActionCard {
        public static let iconBox: CGFloat = 40
        public static let chevron: CGFloat = 20
    }
}
