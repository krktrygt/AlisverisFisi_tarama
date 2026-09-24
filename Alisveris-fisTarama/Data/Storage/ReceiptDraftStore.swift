//
//  ReceiptDraftStore.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import UIKit

public actor ReceiptDraftStore {
    public static let shared = ReceiptDraftStore()

    private let fileManager = FileManager.default
    private let draftBaseDirName = "DraftScans"

    private var draftDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent(draftBaseDirName, isDirectory: true)
    }

    public init() {
        ensureDirectoryExists()
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: draftDirectoryURL.path) {
            let attrs: [FileAttributeKey: Any] = [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try? fileManager.createDirectory(at: draftDirectoryURL, withIntermediateDirectories: true, attributes: attrs)
        }
    }

    public func saveDraft(id: UUID, image: Data?, dto: ParsedReceiptDTO) throws {
        ensureDirectoryExists()
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: sessionDir.path) {
            try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        }

        // 1. Görseli kaydet
        if let imageData = image {
            let imageURL = sessionDir.appendingPathComponent("image.jpg")
            try imageData.write(to: imageURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }

        // 2. DTO'yu JSON olarak kaydet
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(dto)
        try jsonData.write(to: jsonURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func updateDraftMetadata(id: UUID, dto: ParsedReceiptDTO) throws {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: sessionDir.path) else { return }
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(dto)
        try jsonData.write(to: jsonURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func loadDraft(id: UUID) throws -> (ParsedReceiptDTO, UIImage?)? {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        guard fileManager.fileExists(atPath: jsonURL.path) else { return nil }

        let jsonData = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(ParsedReceiptDTO.self, from: jsonData)

        var image: UIImage? = nil
        let imageURL = sessionDir.appendingPathComponent("image.jpg")
        if fileManager.fileExists(atPath: imageURL.path) {
            image = UIImage(contentsOfFile: imageURL.path)
        }

        return (dto, image)
    }

    public func deleteDraft(id: UUID) throws {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        if fileManager.fileExists(atPath: sessionDir.path) {
            try fileManager.removeItem(at: sessionDir)
        }
    }

    public func getLatestDraft() throws -> (UUID, ParsedReceiptDTO, UIImage?)? {
        ensureDirectoryExists()
        guard let subdirs = try? fileManager.contentsOfDirectory(at: draftDirectoryURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return nil
        }

        let sortedDirs = subdirs.sorted { dir1, dir2 in
            let date1 = (try? dir1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? dir2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 > date2
        }

        for dir in sortedDirs {
            if let uuid = UUID(uuidString: dir.lastPathComponent),
               let (dto, img) = try loadDraft(id: uuid) {
                return (uuid, dto, img)
            }
        }
        return nil
    }

    public func purgeExpiredDrafts(olderThanDays days: Int = 7) {
        guard let subdirs = try? fileManager.contentsOfDirectory(at: draftDirectoryURL, includingPropertiesForKeys: [.creationDateKey]) else { return }
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        for dir in subdirs {
            let res = try? dir.resourceValues(forKeys: [.creationDateKey])
            if let creationDate = res?.creationDate, creationDate < expirationDate {
                try? fileManager.removeItem(at: dir)
            }
        }
    }
}
