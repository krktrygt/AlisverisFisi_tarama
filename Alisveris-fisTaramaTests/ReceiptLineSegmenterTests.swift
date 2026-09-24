//
//  ReceiptLineSegmenterTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import CoreGraphics
import Vision
@testable import Alisveris_fisTarama

struct ReceiptLineSegmenterTests {

    @Test func testOCRWordBoxGeometryCalculations() {
        let box = OCRWordBox(
            text: "MİGROS",
            confidence: 0.98,
            boundingBox: CGRect(x: 10, y: 20, width: 80, height: 16)
        )

        #expect(box.midX == 50)
        #expect(box.midY == 28)
        #expect(box.height == 16)
        #expect(box.text == "MİGROS")
    }

    @Test func testSegmentedReceiptLineSortingAndBoundingBox() {
        let word1 = OCRWordBox(
            text: "SÜT",
            confidence: 0.95,
            boundingBox: CGRect(x: 10, y: 50, width: 40, height: 15)
        )
        let word2 = OCRWordBox(
            text: "1L",
            confidence: 0.90,
            boundingBox: CGRect(x: 60, y: 50, width: 25, height: 15)
        )
        let word3 = OCRWordBox(
            text: "35.50",
            confidence: 0.99,
            boundingBox: CGRect(x: 150, y: 50, width: 45, height: 15)
        )

        // Kelimeler karışık sırada verilse bile X eksenine göre doğru dizilmeli
        let line = SegmentedReceiptLine(words: [word3, word1, word2])

        #expect(line.fullText == "SÜT 1L 35.50")
        #expect(line.averageY == 57.5)
        #expect(line.boundingBox.minX == 10)
        #expect(line.boundingBox.maxX == 195)
        #expect(line.boundingBox.minY == 50)
        #expect(line.boundingBox.maxY == 65)
    }

    @Test func testLineSegmenterWithEmptyObservations() {
        let segmenter = ReceiptLineSegmenter()
        let result = segmenter.segment(observations: [], imageSize: CGSize(width: 300, height: 600))
        #expect(result.isEmpty)
    }

    @Test func testRetailVocabularyContents() {
        #expect(ReceiptOCRService.customRetailVocabulary.contains("MİGROS"))
        #expect(ReceiptOCRService.customRetailVocabulary.contains("TOPLAM"))
        #expect(ReceiptOCRService.customRetailVocabulary.contains("KDV"))
        #expect(ReceiptOCRService.customRetailVocabulary.contains("İNDİRİM"))
    }
}
