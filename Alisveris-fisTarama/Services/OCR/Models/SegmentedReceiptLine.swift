//
//  SegmentedReceiptLine.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import CoreGraphics

public struct SegmentedReceiptLine: Identifiable, Sendable {
    public let id: UUID
    public var words: [OCRWordBox]

    public init(id: UUID = UUID(), words: [OCRWordBox]) {
        self.id = id
        self.words = words
    }

    public var averageY: CGFloat {
        guard !words.isEmpty else { return 0 }
        return words.reduce(0) { $0 + $1.midY } / CGFloat(words.count)
    }

    public var fullText: String {
        words.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX })
            .map { $0.text }
            .joined(separator: " ")
    }

    public var boundingBox: CGRect {
        guard !words.isEmpty else { return .zero }
        let minX = words.map(\.boundingBox.minX).min() ?? 0
        let minY = words.map(\.boundingBox.minY).min() ?? 0
        let maxX = words.map(\.boundingBox.maxX).max() ?? 0
        let maxY = words.map(\.boundingBox.maxY).max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
