//
//  ChatCopy.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

/// Key copy Tanya AI di `Resources/*.lproj/Localizable.strings`. Satu-satunya tempat key ditulis;
/// `LocalizationTests` memastikan setiap case ada di en/id/zh-Hans dan tidak ada key yang yatim.
enum ChatCopy: String, CaseIterable {
    case placeholder = "chat.placeholder"
    case send = "chat.send"
    case title = "chat.title"
    case back = "chat.back"
    case sending = "chat.sending"
    case stop = "chat.stop"
    case shortcutsTitle = "welcome.shortcutsTitle"
}
