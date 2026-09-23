//
//  UnitType.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Alışveriş kalemleri için ölçü birimi tipi
public enum UnitType: String, Codable, CaseIterable, Sendable {
    case piece = "PIECE"          // Adet
    case kilogram = "KILOGRAM"    // Kilogram (kg)
    case gram = "GRAM"            // Gram (g)
    case liter = "LITER"          // Litre (L)
    case milliliter = "MILLILITER"// Mililitre (ml)
    case pack = "PACK"            // Paket
    case box = "BOX"              // Kutu / Koli

    public var localizedTitle: String {
        switch self {
        case .piece: return "adet"
        case .kilogram: return "kg"
        case .gram: return "g"
        case .liter: return "L"
        case .milliliter: return "ml"
        case .pack: return "paket"
        case .box: return "kutu"
        }
    }

    public enum Dimension: Sendable {
        case weight     // Standart Baz: Kilogram
        case volume     // Standart Baz: Litre
        case discrete   // Standart Baz: Adet
    }

    public var dimension: Dimension {
        switch self {
        case .kilogram, .gram:
            return .weight
        case .liter, .milliliter:
            return .volume
        case .piece, .pack, .box:
            return .discrete
        }
    }

    /// Standart baz birime dönüştürme çarpanı (Örn: gram -> kg için 0.001)
    public var baseConversionFactor: Decimal {
        switch self {
        case .kilogram: return Decimal(1.0)
        case .gram: return Decimal(sign: .plus, exponent: -3, significand: 1) // 0.001
        case .liter: return Decimal(1.0)
        case .milliliter: return Decimal(sign: .plus, exponent: -3, significand: 1) // 0.001
        case .piece, .pack, .box: return Decimal(1.0)
        }
    }

    /// İlgili boyutun standart baz birim karşılığı (.kg, .liter, .piece)
    public var baseUnit: UnitType {
        switch self.dimension {
        case .weight: return .kilogram
        case .volume: return .liter
        case .discrete: return .piece
        }
    }
}
