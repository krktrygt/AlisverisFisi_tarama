//
//  ReceiptState.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import SwiftData

public enum ReceiptError: Error, Sendable, LocalizedError {
    case preprocessingFailed(String)
    case ocrEngineFailed(String)
    case parsingFailed(String)
    case persistenceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .preprocessingFailed(let message):
            return "Görsel işleme hatası: \(message)"
        case .ocrEngineFailed(let message):
            return "Metin okuma hatası: \(message)"
        case .parsingFailed(let message):
            return "Fiş ayrıştırma hatası: \(message)"
        case .persistenceFailed(let message):
            return "Kayıt hatası: \(message)"
        }
    }
}

public enum RecoveryState: Sendable {
    case canRetryPersistence(ParsedReceiptDTO)
    case canReturnToVerification(ParsedReceiptDTO)
    case canRestartScan
}

public enum ReceiptState: Sendable {
    case idle
    case scanning
    case preprocessing
    case ocrProcessing
    case parsing
    case verificationPending(ParsedReceiptDTO)
    case persisting
    case completed(PersistentIdentifier)
    case failed(ReceiptError, recovery: RecoveryState)
}
