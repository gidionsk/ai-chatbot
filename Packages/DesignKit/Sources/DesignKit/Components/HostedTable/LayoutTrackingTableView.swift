//
//  LayoutTrackingTableView.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import UIKit

/// Table yang melapor setelah layout mengubah ukuran area atau ukuran kontennya.
public final class LayoutTrackingTableView: UITableView {
    public var onLayoutChange: (() -> Void)?
    private var trackedBoundsSize = CGSize.zero
    private var trackedContentSize = CGSize.zero

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard trackedBoundsSize != bounds.size || trackedContentSize != contentSize else { return }
        trackedBoundsSize = bounds.size
        trackedContentSize = contentSize
        onLayoutChange?()
    }
}
