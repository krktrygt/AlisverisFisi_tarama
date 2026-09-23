//
//  UnitConverter.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Birim Fiyat Dönüştürücü
public enum UnitConverter: Sendable {
    /// Herhangi bir birimdeki fiyatı ambalaj veya tartı miktarına göre standart baz birime (₺/kg, ₺/L veya ₺/adet) dönüştürür.
    /// Çift bölme hatasını (P / Q^2) önler:
    /// - Ham birim zaten standart baz birim ise (kg, L, adet), normalizedPrice doğrudan rawUnitPrice'tır.
    /// - Ham birim bir alt birim ise (gram, ml, cl), normalizedPrice = totalPrice / normalizedQuantity
    ///   burada normalizedQuantity = rawQuantity * conversionMultiplier (örn. 500g için 0.5 kg).
    public static func normalizePriceToBaseUnit(
        totalPrice: Decimal,
        rawUnitPrice: Decimal,
        quantity: Decimal,
        unit: UnitType
    ) -> Decimal {
        guard quantity > 0 else { return rawUnitPrice }
        switch unit {
        case .gram:
            let kg = quantity / Decimal(1000)
            return kg > 0 ? (totalPrice / kg) : rawUnitPrice
        case .milliliter:
            let liters = quantity / Decimal(1000)
            return liters > 0 ? (totalPrice / liters) : rawUnitPrice
        case .kilogram, .liter:
            return rawUnitPrice
        case .piece, .pack, .box:
            return rawUnitPrice
        }
    }

    /// Aşırı yükleme (Geriye dönük API uyumluluğu)
    public static func normalizePriceToBaseUnit(
        unitPrice: Decimal,
        quantity: Decimal,
        unit: UnitType
    ) -> Decimal {
        normalizePriceToBaseUnit(
            totalPrice: unitPrice,
            rawUnitPrice: unitPrice,
            quantity: quantity,
            unit: unit
        )
    }
}
