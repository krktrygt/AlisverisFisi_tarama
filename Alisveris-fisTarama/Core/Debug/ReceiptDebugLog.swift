//
//  ReceiptDebugLog.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public struct ReceiptPipelineStageLog: Codable, Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let stageName: String
    public let summary: String
    public let details: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        stageName: String,
        summary: String,
        details: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.stageName = stageName
        self.summary = summary
        self.details = details
    }
}

public struct ReceiptSessionDebugLog: Codable, Sendable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public var rawOCRText: String
    public var segmentedLineCount: Int
    public var detectedStore: String?
    public var detectedTotal: Decimal?
    public var parsedItemCount: Int
    public var stages: [ReceiptPipelineStageLog]

    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        rawOCRText: String = "",
        segmentedLineCount: Int = 0,
        detectedStore: String? = nil,
        detectedTotal: Decimal? = nil,
        parsedItemCount: Int = 0,
        stages: [ReceiptPipelineStageLog] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.rawOCRText = rawOCRText
        self.segmentedLineCount = segmentedLineCount
        self.detectedStore = detectedStore
        self.detectedTotal = detectedTotal
        self.parsedItemCount = parsedItemCount
        self.stages = stages
    }
}
