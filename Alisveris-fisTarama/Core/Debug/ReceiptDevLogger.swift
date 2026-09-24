//
//  ReceiptDevLogger.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public actor ReceiptDevLogger {
    public static let shared = ReceiptDevLogger()

    private let fileManager: FileManager
    private let directoryURL: URL
    private var activeSessions: [UUID: ReceiptSessionDebugLog] = [:]

    public init(fileManager: FileManager = .default, customURL: URL? = nil) {
        self.fileManager = fileManager
        if let customURL {
            self.directoryURL = customURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directoryURL = appSupport.appendingPathComponent("DevLogs", isDirectory: true)
        }
        try? fileManager.createDirectory(at: self.directoryURL, withIntermediateDirectories: true)
    }

    public func startSession(id: UUID = UUID()) -> UUID {
        let session = ReceiptSessionDebugLog(id: id, startTime: Date())
        activeSessions[id] = session
        return id
    }

    public func logStage(sessionId: UUID, stageName: String, summary: String, details: String) {
        guard var session = activeSessions[sessionId] else { return }
        let stage = ReceiptPipelineStageLog(stageName: stageName, summary: summary, details: details)
        session.stages.append(stage)
        activeSessions[sessionId] = session
    }

    public func finishSession(
        sessionId: UUID,
        rawOCRText: String,
        segmentedLineCount: Int,
        detectedStore: String?,
        detectedTotal: Decimal?,
        parsedItemCount: Int
    ) {
        guard var session = activeSessions[sessionId] else { return }
        session.endTime = Date()
        session.rawOCRText = rawOCRText
        session.segmentedLineCount = segmentedLineCount
        session.detectedStore = detectedStore
        session.detectedTotal = detectedTotal
        session.parsedItemCount = parsedItemCount

        activeSessions[sessionId] = session
        saveSessionToDisk(session: session)
    }

    private func saveSessionToDisk(session: ReceiptSessionDebugLog) {
        let filename = "\(ISO8601DateFormatter().string(from: session.startTime))_\(session.id.uuidString).json"
        let fileURL = directoryURL.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(session) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    public func fetchAllLogs() -> [ReceiptSessionDebugLog] {
        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return Array(activeSessions.values)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var results: [ReceiptSessionDebugLog] = []
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let log = try? decoder.decode(ReceiptSessionDebugLog.self, from: data) {
                results.append(log)
            }
        }

        // Aktif hafızadakilerle birleştir ve tarihe göre azalan sırala
        for session in activeSessions.values {
            if !results.contains(where: { $0.id == session.id }) {
                results.append(session)
            }
        }

        return results.sorted { $0.startTime > $1.startTime }
    }

    public func exportAllLogsAsJSONString() -> String {
        let allLogs = fetchAllLogs()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(allLogs),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }

    public func exportSingleLogAsJSONString(log: ReceiptSessionDebugLog) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(log),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }

    public func exportAllLogsAsTempFileURL() -> URL? {
        let jsonString = exportAllLogsAsJSONString()
        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Receipt_DevLogs_Export_\(Int(Date().timeIntervalSince1970)).json")
        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    public func clearAllLogs() {
        activeSessions.removeAll()
        if let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
