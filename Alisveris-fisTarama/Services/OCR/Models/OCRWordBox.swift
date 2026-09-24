//
//  OCRWordBox.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import CoreGraphics

public struct OCRWordBox: Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public var midX: CGFloat { boundingBox.midX }
    public var midY: CGFloat { boundingBox.midY }
    public var height: CGFloat { boundingBox.height }

    public init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: CGRect
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}
