//
//  SandboxCopy.swift
//  TanyaAISandbox
//
//  Created by Wendra on 27/10/26.
//

import DesignKit
import Foundation

/// Key copy sandbox di `Resources/*.lproj/Localizable.strings`. Satu-satunya tempat key ditulis;
/// `SandboxCopyTests` memastikan setiap case ada di en/id/zh-Hans dan tidak ada key yang yatim.
enum SandboxCopy: String, CaseIterable {
    case open = "sandbox.open"
    case demoTitle = "sandbox.demo.title"
    case demoBody = "sandbox.demo.body"
    case demoEnd = "sandbox.demo.end"
    case toggleTitle = "sandbox.formToggle.title"
    case toggleOn = "sandbox.formToggle.on"
    case toggleOff = "sandbox.formToggle.off"
    case toggleChangeValue = "sandbox.formToggle.changeValue"
    case toggleEnabled = "sandbox.formToggle.enabled"
    case toggleFormEnabled = "sandbox.formToggle.formEnabled"
    case mainTitle = "sandbox.main.title"
    case detailOpen = "sandbox.detail.open"
    case detailTitle = "sandbox.detail.title"
    case back = "sandbox.back"
    case offlineSimulate = "sandbox.offline.simulate"
    case offlineTitle = "sandbox.offline.title"
    case offlineRetry = "sandbox.offline.retry"
    case logout = "sandbox.logout"
    case login = "sandbox.login"
    case preloginTitle = "sandbox.prelogin.title"
    case linkTitle = "sandbox.link.title"
    case linkClose = "sandbox.link.close"
    case sheetOpen = "sandbox.sheet.open"
    case sheetTitle = "sandbox.sheet.title"
    case sheetOption = "sandbox.sheet.option"
    case sheetClose = "sandbox.sheet.close"
}

extension String {
    /// Copy sandbox dari bundle app sesuai locale host.
    init(_ copy: SandboxCopy, locale: Locale) {
        self.init(key: copy.rawValue, bundle: .main, locale: locale)
    }
}
