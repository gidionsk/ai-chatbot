//
//  MarkdownColumnAlignment.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation
import SwiftUI

/// Perataan kolom tabel dari baris pemisah GFM (`:---`, `:---:`, `---:`); tanpa titik dua = kiri.
enum MarkdownColumnAlignment: Equatable, Sendable {
    case leading
    case center
    case trailing

    init(_ alignment: PresentationIntent.TableColumn.Alignment) {
        switch alignment {
        case .center:
            self = .center
        case .right:
            self = .trailing
        default:
            self = .leading
        }
    }

    var frameAlignment: Alignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}
