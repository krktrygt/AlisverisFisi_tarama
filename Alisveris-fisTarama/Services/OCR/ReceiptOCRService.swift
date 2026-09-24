//
//  ReceiptOCRService.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Vision
import CoreGraphics

public final class ReceiptOCRService: Sendable {
    public static let customRetailVocabulary: [String] = [
        "MİGROS", "MIGROS", "BİM", "BIM", "A101", "ŞOK", "SOK", "CARREFOURSA",
        "KDV", "TOPKDV", "TOPLAM", "ARA TOPLAM", "GENEL TOPLAM",
        "FİŞ", "FIS", "TARİH", "TARIH", "SAAT", "NO", "ŞUBE", "SUBE",
        "NAKİT", "NAKIT", "KREDİ", "KREDI", "KARTI", "TEMASSIZ",
        "İNDİRİM", "INDIRIM", "KAMPANYA", "İSKONTO", "TUTAR",
        "KG", "GR", "ADET", "AD", "PK", "PAKET", "LT", "L"
    ]
    
    public init() {}
    
    public func performOCR(on cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = req.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["tr-TR", "en-US"]
            request.usesLanguageCorrection = true
            request.customWords = ReceiptOCRService.customRetailVocabulary

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
