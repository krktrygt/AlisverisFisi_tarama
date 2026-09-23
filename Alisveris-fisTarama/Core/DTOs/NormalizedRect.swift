//
//  NormalizedRect.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import CoreGraphics

/// Görüntü koordinatları için Sendable sınırlayıcı kutu
public struct NormalizedRect: Sendable, Equatable, Codable {
    public let originX: CGFloat
    public let originY: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public init(originX: CGFloat, originY: CGFloat, width: CGFloat, height: CGFloat) {
        self.originX = originX
        self.originY = originY
        self.width = width
        self.height = height
    }

    public var cgRect: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }
}
