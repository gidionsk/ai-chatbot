//
//  FontLoader.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import CoreText
import Foundation

/// Registers process-scoped fonts once. Call during app setup, before creating themes.
public enum FontLoader {
    private static let lock = NSLock()
    private static var registered: [URL: [String]] = [:]

    public enum Failure: Error {
        case missingResource(String)
        case invalidFont(URL)
        case registration(URL)
    }

    /// Returns the actual PostScript names, which may differ from the file name.
    public static func register(url: URL) throws -> [String] {
        lock.lock()
        defer { lock.unlock() }
        if let names = registered[url] { return names }
        guard
            let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL)
                as? [CTFontDescriptor], !descriptors.isEmpty
        else {
            throw Failure.invalidFont(url)
        }
        var error: Unmanaged<CFError>?
        let isRegistered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        let failure = error?.takeRetainedValue()
        guard
            isRegistered
                || failure.map({
                    CFErrorGetDomain($0) as String == kCTFontManagerErrorDomain as String
                        && CFErrorGetCode($0) == CTFontManagerError.alreadyRegistered.rawValue
                }) == true
        else {
            throw Failure.registration(url)
        }
        let names = descriptors.compactMap {
            CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String
        }
        registered[url] = names
        return names
    }

    public static func register(
        fileNames: [String],
        bundle: Bundle,
        subdirectory: String? = nil
    ) throws -> [String] {
        try fileNames.flatMap { fileName in
            guard
                let resource = bundle.url(
                    forResource: fileName, withExtension: nil, subdirectory: subdirectory
                )
            else {
                throw Failure.missingResource(fileName)
            }
            return try register(url: resource)
        }
    }
}
