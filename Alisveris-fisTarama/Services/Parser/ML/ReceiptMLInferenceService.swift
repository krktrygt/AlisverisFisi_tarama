//
//  ReceiptMLInferenceService.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import CoreML

public actor ReceiptMLInferenceService: Sendable {
    public static let shared = ReceiptMLInferenceService()

    private let classifier: Alisveris_Fis_Takip_Classifier1?
    private let tagger: Alisveris_Fis_Takip_tagger1?
    private let categoryClassifier: Alisveris_Fis_takip_kategori_classifier1?

    public init(configuration: MLModelConfiguration = MLModelConfiguration()) {
        self.classifier = try? Alisveris_Fis_Takip_Classifier1(configuration: configuration)
        self.tagger = try? Alisveris_Fis_Takip_tagger1(configuration: configuration)
        self.categoryClassifier = try? Alisveris_Fis_takip_kategori_classifier1(configuration: configuration)
    }

    public func classify(text: String) -> (role: ReceiptLineRole, rawLabel: String, confidence: Double) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let classifier = classifier else {
            return (.unknown, "UNKNOWN", 0.0)
        }

        do {
            let output = try classifier.prediction(text: trimmed)
            let raw = output.label
            let role = ReceiptLineRole.from(rawLabel: raw)
            return (role, raw, 0.95)
        } catch {
            return (.unknown, "ERROR", 0.0)
        }
    }

    public func tagTokens(in text: String) -> [TaggedTokenResult] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let tagger = tagger else {
            return []
        }

        do {
            let output = try tagger.prediction(text: trimmed)
            let count = min(output.tokens.count, output.labels.count, output.locations.count, output.lengths.count)
            var results: [TaggedTokenResult] = []
            results.reserveCapacity(count)

            for i in 0..<count {
                results.append(
                    TaggedTokenResult(
                        token: output.tokens[i],
                        label: output.labels[i],
                        location: Int(output.locations[i]),
                        length: Int(output.lengths[i])
                    )
                )
            }
            return results
        } catch {
            return []
        }
    }

    public func classifyLines(_ lines: [SegmentedReceiptLine]) async -> [ClassifiedReceiptLine] {
        lines.map { line in
            let res = classify(text: line.fullText)
            return ClassifiedReceiptLine(line: line, role: res.role, rawLabel: res.rawLabel, confidence: res.confidence)
        }
    }

    /// Ürün ismi için 20 perakende kategorisinden en uygununu tahmin eder
    nonisolated public func predictCategory(for text: String) -> (rawCode: String, category: StandardCategory, confidence: Double) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let categoryClassifier = categoryClassifier else {
            return (StandardCategory.otherNonFood.rawCode, .otherNonFood, 0.5)
        }

        // Maximum Entropy modelinin en yüksek isabetle çalıştığı ASCII eşdeğeri (Örn: SÜZMEPEY -> SUZMEPEY, POŞET -> POSET)
        let asciiNormalized = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "I", with: "I")
            .uppercased()

        do {
            let output = try categoryClassifier.prediction(text: asciiNormalized)
            let rawCode = output.label
            let standard = StandardCategory.from(rawCode: rawCode)
            return (rawCode, standard, 0.90)
        } catch {
            return (StandardCategory.otherNonFood.rawCode, .otherNonFood, 0.0)
        }
    }
}
