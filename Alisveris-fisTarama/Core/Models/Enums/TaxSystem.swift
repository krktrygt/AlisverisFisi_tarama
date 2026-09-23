//
//  TaxSystem.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Fişin ait olduğu pazarın vergi rejimi
public enum TaxSystem: String, Codable, CaseIterable, Sendable {
    /// Fiyatlara KDV dahildir (Türkiye, AB, İngiltere)
    case inclusiveVAT = "INCLUSIVE_VAT"
    /// Satış vergisi fiş sonunda eklenir (ABD, Kanada)
    case exclusiveSalesTax = "EXCLUSIVE_SALES_TAX"

    public var localizedTitle: String {
        switch self {
        case .inclusiveVAT: return "Dahil KDV (VAT/MwSt)"
        case .exclusiveSalesTax: return "Hariç Satış Vergisi (Sales Tax)"
        }
    }
}
