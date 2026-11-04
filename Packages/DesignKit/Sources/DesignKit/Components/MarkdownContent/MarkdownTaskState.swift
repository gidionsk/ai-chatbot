//
//  MarkdownTaskState.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

/// Status item task list GFM (`- [ ]`, `- [x]`). Hanya tampilan: pesan bot tidak bisa dicentang pengguna.
enum MarkdownTaskState: Equatable, Sendable {
    case open
    case done
}
