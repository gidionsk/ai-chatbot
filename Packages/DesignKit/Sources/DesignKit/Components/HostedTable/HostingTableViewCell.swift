//
//  HostingTableViewCell.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI
import UIKit

/// Sel table berisi view SwiftUI. iOS 16+ memakai `UIHostingConfiguration`; iOS 15 memakai hosting controller yang
/// dipakai ulang dengan containment eksplisit. Sel hosting tidak mewarisi environment SwiftUI dari pemakai table,
/// jadi nilai environment harus dipasang pada `rootView`.
public final class HostingTableViewCell<Content: View>: UITableViewCell, HostedContentAttaching {
    public static var reuseIdentifier: String { String(reflecting: Self.self) }
    private var hostingController: UIHostingController<Content?>?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { nil }

    public func configure(rootView: Content, parent: UIViewController) {
        guard #available(iOS 16, *) else {
            configureLegacy(rootView: rootView, parent: parent)
            return
        }
        contentConfiguration = UIHostingConfiguration { rootView }.margins(.all, .zero)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        clearHostedContent()
    }

    public func attachHostedController(to parent: UIViewController) {
        guard let hostingController, hostingController.parent !== parent, let hostedView = hostingController.view
        else { return }
        detachHostedController()
        parent.addChild(hostingController)
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        hostingController.didMove(toParent: parent)
    }

    /// Dilepas saat keluar layar atau dibongkar; controller-nya dipakai lagi oleh `configure`.
    public func detachHostedController() {
        guard let hostingController, hostingController.parent != nil else { return }
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
    }
}

// MARK: - Helpers

extension HostingTableViewCell {
    func configureLegacy(rootView: Content, parent: UIViewController) {
        guard let hostingController else {
            let controller = UIHostingController(rootView: Optional(rootView))
            controller.view.backgroundColor = .clear
            hostingController = controller
            attachHostedController(to: parent)
            return
        }
        hostingController.rootView = rootView
        hostingController.view.invalidateIntrinsicContentSize()
        attachHostedController(to: parent)
    }

    private func clearHostedContent() {
        if #available(iOS 16, *) { contentConfiguration = nil }
        hostingController?.rootView = nil
        detachHostedController()
    }
}
