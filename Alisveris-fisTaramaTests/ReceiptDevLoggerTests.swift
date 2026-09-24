//
//  ReceiptDevLoggerTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import Foundation
@testable import Alisveris_fisTarama

struct ReceiptDevLoggerTests {

    @Test func testDevLoggerSessionLifecycle() async {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let logger = ReceiptDevLogger(customURL: tempDir)

        let sessionId = await logger.startSession()

        await logger.logStage(
            sessionId: sessionId,
            stageName: "OCR",
            summary: "10 bloğu okundu",
            details: "BİM BİRLEŞİK MAĞAZALAR\nSÜT 35.00 TL"
        )

        await logger.finishSession(
            sessionId: sessionId,
            rawOCRText: "BİM BİRLEŞİK MAĞAZALAR\nSÜT 35.00 TL",
            segmentedLineCount: 2,
            detectedStore: "BİM",
            detectedTotal: Decimal(35),
            parsedItemCount: 1
        )

        let logs = await logger.fetchAllLogs()
        #expect(logs.count == 1)
        #expect(logs.first?.detectedStore == "BİM")
        #expect(logs.first?.detectedTotal == Decimal(35))
        #expect(logs.first?.stages.count == 1)
        #expect(logs.first?.stages.first?.stageName == "OCR")

        await logger.clearAllLogs()
        let logsAfterClear = await logger.fetchAllLogs()
        #expect(logsAfterClear.isEmpty)
    }
}
