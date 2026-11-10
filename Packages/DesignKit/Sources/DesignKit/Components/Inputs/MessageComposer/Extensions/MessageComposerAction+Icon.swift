//
//  MessageComposerAction+Icon.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

extension MessageComposerAction {
    /// Kirim aktif/nonaktif punya ikon sendiri; stop dan stopping sama-sama `send-pause`.
    func icon(isEnabled: Bool) -> DesignColorIcon {
        switch self {
        case .send:
            return isEnabled ? .sendOn : .sendOff
        case .stop, .stopping:
            return .sendPause
        }
    }

    /// Hanya stopping yang memakai redup `disabled` bawaan sistem; fase lain menampilkan aset apa adanya.
    var isSystemDimmed: Bool { self == .stopping }
}
