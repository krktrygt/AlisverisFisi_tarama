//
//  ReceiptImageDiskManager.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import UIKit

public protocol ReceiptImageDiskManagerProtocol: Sendable {
    func saveReceiptImage(data: Data, filename: String) throws -> String
    func loadReceiptImage(relativePath: String) -> UIImage?
    func deleteImage(relativePath: String) throws
}

public final class ReceiptImageDiskManager: @unchecked Sendable, ReceiptImageDiskManagerProtocol {
    public static let shared = ReceiptImageDiskManager()

    private let fileManager: FileManager
    private let baseDirectoryName = "ReceiptImages"
    private let customBaseURL: URL?

    public init(fileManager: FileManager = .default, customBaseURL: URL? = nil) {
        self.fileManager = fileManager
        self.customBaseURL = customBaseURL
        ensureDirectoryExists()
    }

    private var applicationSupportDirectory: URL {
        if let customBaseURL {
            return customBaseURL
        }
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private var imagesDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent(baseDirectoryName, isDirectory: true)
    }

    private func ensureDirectoryExists() {
        let dirURL = imagesDirectoryURL
        if !fileManager.fileExists(atPath: dirURL.path) {
            let attributes: [FileAttributeKey: Any] = [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: attributes)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false // iCloud yedeklemesine dahil et
            var mutableDir = dirURL
            try? mutableDir.setResourceValues(resourceValues)
        }
    }

    public func saveReceiptImage(data: Data, filename: String) throws -> String {
        ensureDirectoryExists()
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return "\(baseDirectoryName)/\(filename)"
    }

    public func loadReceiptImage(relativePath: String) -> UIImage? {
        let fullURL = applicationSupportDirectory.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: fullURL.path) else { return nil }
        return UIImage(contentsOfFile: fullURL.path)
    }

    public func deleteImage(relativePath: String) throws {
        let fullURL = applicationSupportDirectory.appendingPathComponent(relativePath)
        if fileManager.fileExists(atPath: fullURL.path) {
            try fileManager.removeItem(at: fullURL)
        }
    }
}
