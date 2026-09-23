//
//  PaymentMethod.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Alışveriş fişinde kullanılan ödeme yöntemi
public enum PaymentMethod: String, Codable, CaseIterable, Sendable {
    case creditCard = "CREDIT_CARD"
    case debitCard = "DEBIT_CARD"
    case cash = "CASH"
    case mealCard = "MEAL_CARD"
    case digitalWallet = "DIGITAL_WALLET"
    case other = "OTHER"

    public var localizedTitle: String {
        switch self {
        case .creditCard: return "Kredi Kartı"
        case .debitCard: return "Banka Kartı"
        case .cash: return "Nakit"
        case .mealCard: return "Yemek Kartı"
        case .digitalWallet: return "Dijital Cüzdan"
        case .other: return "Diğer"
        }
    }
}
