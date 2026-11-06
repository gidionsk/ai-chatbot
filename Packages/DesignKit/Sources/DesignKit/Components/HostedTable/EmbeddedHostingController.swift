//
//  EmbeddedHostingController.swift
//  DesignKit
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI

/// Hosting controller di dalam sel. Navigation controller disembunyikan darinya, karena di iOS 15 hosting controller
/// child memunculkan lagi navigation bar yang disembunyikan host. Sel tidak butuh navigasi: itu milik host.
final class EmbeddedHostingController<Content: View>: UIHostingController<Content> {
    override var navigationController: UINavigationController? { nil }
}
