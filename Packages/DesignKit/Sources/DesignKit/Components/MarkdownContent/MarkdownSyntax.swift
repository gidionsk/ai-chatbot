//
//  MarkdownSyntax.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// Nilai sintaks Markdown (bukan token desain): level heading, nomor awal list, dan penanda bullet.
enum MarkdownSyntax {
    /// `#`.
    static let titleLevel = 1
    /// `##`.
    static let sectionLevel = 2
    /// Satu list di dalam item list = satu level lebih dalam.
    static let nestingStep = 1
    /// Nomor item list bila parser tidak memberinya.
    static let firstOrdinal = 1
    /// Bullet berganti per level agar list bertingkat mudah dibedakan. U+FE0E menjaga `▪` tetap glyph teks.
    private static let bullets = ["•", "◦", "▪\u{FE0E}"]

    /// Panjang `[ ] ` dan `[x] `.
    static let taskPrefixLength = 4
    /// U+FE0E menjaga kotak tetap glyph teks, bukan emoji.
    private static let openTaskMarker = "\u{2610}\u{FE0E}"
    private static let doneTaskMarker = "\u{2611}\u{FE0E}"

    static func taskState(prefix: String) -> MarkdownTaskState? {
        switch prefix {
        case "[ ] ":
            return .open
        case "[x] ", "[X] ":
            return .done
        default:
            return nil
        }
    }

    /// Item task memakai kotak menggantikan bullet; pada list bernomor nomornya tetap tampil.
    static func listMarker(ordinal: Int, isOrdered: Bool, depth: Int, task: MarkdownTaskState? = nil) -> String {
        let plain = isOrdered ? "\(ordinal)." : bullets[depth % bullets.count]
        guard let task = task else { return plain }
        let box = task == .done ? doneTaskMarker : openTaskMarker
        return isOrdered ? "\(plain) \(box)" : box
    }
}
