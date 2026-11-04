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
    /// Bullet berganti per level agar list bertingkat mudah dibedakan.
    private static let bullets = ["•", "◦", "▪"]

    static func listMarker(ordinal: Int, isOrdered: Bool, depth: Int) -> String {
        isOrdered ? "\(ordinal)." : bullets[depth % bullets.count]
    }
}
