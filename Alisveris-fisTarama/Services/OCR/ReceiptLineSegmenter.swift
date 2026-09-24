//
//  ReceiptLineSegmenter.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import CoreGraphics
import Vision

public final class ReceiptLineSegmenter: Sendable {

    public init() {}

    public func segment(observations: [VNRecognizedTextObservation], imageSize: CGSize) -> [SegmentedReceiptLine] {
        guard !observations.isEmpty else { return [] }

        // 1. Koordinatları UIKit piksel sistemine dönüştür (Sol-Alt -> Sol-Üst)
        let wordBoxes: [OCRWordBox] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            let box = obs.boundingBox
            let uikitRect = CGRect(
                x: box.origin.x * imageSize.width,
                y: (1.0 - box.origin.y - box.height) * imageSize.height,
                width: box.width * imageSize.width,
                height: box.height * imageSize.height
            )
            return OCRWordBox(text: candidate.string, confidence: candidate.confidence, boundingBox: uikitRect)
        }

        guard !wordBoxes.isEmpty else { return [] }

        // 2. Dominant Eğim Açısını (Skew Angle Theta) Hesapla
        let skewAngle = calculateDominantSkewAngle(observations: observations)

        // 3. Kelime kutularını ters eğim açısıyla sanal olarak döndür (Rotational Deskewing)
        let centerPoint = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
        let deskewedWords: [(box: OCRWordBox, rotatedMidY: CGFloat, rotatedMidX: CGFloat)] = wordBoxes.map { word in
            let rad = -skewAngle
            let dx = word.midX - centerPoint.x
            let dy = word.midY - centerPoint.y
            let rotX = dx * cos(rad) - dy * sin(rad) + centerPoint.x
            let rotY = dx * sin(rad) + dy * cos(rad) + centerPoint.y
            return (word, rotY, rotX)
        }

        // 4. Adaptif deltaY hesabı (Medyan karakter yüksekliğinin %45'i)
        let sortedHeights = wordBoxes.map(\.height).sorted()
        let medianHeight = sortedHeights[sortedHeights.count / 2]
        let deltaY = medianHeight * 0.45

        // 5. Döndürülmüş Y ekseninde kümeleme (En yakın satıra yerleştirme)
        let sortedDeskewed = deskewedWords.sorted { $0.rotatedMidY < $1.rotatedMidY }
        var lineClusters: [[(box: OCRWordBox, rotX: CGFloat, rotY: CGFloat)]] = []

        for item in sortedDeskewed {
            var bestLineIndex: Int? = nil
            var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude

            for (idx, cluster) in lineClusters.enumerated() {
                let clusterAvgY = cluster.reduce(0) { $0 + $1.rotY } / CGFloat(cluster.count)
                let dist = abs(item.rotatedMidY - clusterAvgY)
                if dist <= deltaY && dist < minDistance {
                    minDistance = dist
                    bestLineIndex = idx
                }
            }

            if let targetIdx = bestLineIndex {
                lineClusters[targetIdx].append((item.box, item.rotatedMidX, item.rotatedMidY))
            } else {
                lineClusters.append([(item.box, item.rotatedMidX, item.rotatedMidY)])
            }
        }

        // 6. Satırları dikeyde sırala, her satırın içindeki kelimeleri soldan sağa diz
        return lineClusters.map { cluster in
            let sortedWords = cluster.sorted { $0.rotX < $1.rotX }.map(\.box)
            return SegmentedReceiptLine(words: sortedWords)
        }.sorted { $0.averageY < $1.averageY }
    }

    private func calculateDominantSkewAngle(observations: [VNRecognizedTextObservation]) -> CGFloat {
        var angles: [CGFloat] = []
        for obs in observations {
            let topLeft = obs.topLeft
            let topRight = obs.topRight
            let deltaY = (topRight.y - topLeft.y)
            let deltaX = (topRight.x - topLeft.x)
            guard abs(deltaX) > 0.001 else { continue }
            let angle = atan2(deltaY, deltaX)
            if abs(angle) <= (5.0 * .pi / 180.0) {
                angles.append(angle)
            }
        }
        guard !angles.isEmpty else { return 0.0 }
        let sortedAngles = angles.sorted()
        return sortedAngles[sortedAngles.count / 2]
    }
}
