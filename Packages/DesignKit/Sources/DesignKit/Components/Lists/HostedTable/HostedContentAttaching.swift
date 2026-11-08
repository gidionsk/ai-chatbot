//
//  HostedContentAttaching.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import UIKit

/// Sel yang memasang konten hosting ke parent saat tampil dan melepasnya saat keluar layar. Dipanggil dari
/// delegate table, yang tidak perlu tahu tipe konten selnya.
@MainActor
public protocol HostedContentAttaching: AnyObject {
    func attachHostedController(to parent: UIViewController)
    func detachHostedController()
}
