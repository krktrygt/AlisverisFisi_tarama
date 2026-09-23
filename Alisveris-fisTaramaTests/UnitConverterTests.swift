//
//  UnitConverterTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Testing
import Foundation
@testable import Alisveris_fisTarama

struct UnitConverterTests {

    @Test func testUnitTypeDimensionsAndFactors() {
        #expect(UnitType.kilogram.dimension == .weight)
        #expect(UnitType.gram.dimension == .weight)
        #expect(UnitType.liter.dimension == .volume)
        #expect(UnitType.milliliter.dimension == .volume)
        #expect(UnitType.piece.dimension == .discrete)
        #expect(UnitType.pack.dimension == .discrete)

        #expect(UnitType.gram.baseConversionFactor == Decimal(sign: .plus, exponent: -3, significand: 1))
        #expect(UnitType.kilogram.baseConversionFactor == Decimal(1))
        #expect(UnitType.gram.baseUnit == .kilogram)
        #expect(UnitType.milliliter.baseUnit == .liter)
        #expect(UnitType.pack.baseUnit == .piece)
    }

    @Test func testUnitConverterWeightGramToKg() {
        // 500 gram peynir 150 TL -> kg birim fiyatı 300 TL olmalı
        let totalPrice = Decimal(150)
        let rawUnitPrice = Decimal(150)
        let quantity = Decimal(500) // 500g

        let normalized = UnitConverter.normalizePriceToBaseUnit(
            totalPrice: totalPrice,
            rawUnitPrice: rawUnitPrice,
            quantity: quantity,
            unit: .gram
        )

        #expect(normalized == Decimal(300))
    }

    @Test func testUnitConverterVolumeMlToLiter() {
        // 250 ml süt 25 TL -> Litre fiyatı 100 TL olmalı
        let totalPrice = Decimal(25)
        let rawUnitPrice = Decimal(25)
        let quantity = Decimal(250) // 250ml

        let normalized = UnitConverter.normalizePriceToBaseUnit(
            totalPrice: totalPrice,
            rawUnitPrice: rawUnitPrice,
            quantity: quantity,
            unit: .milliliter
        )

        #expect(normalized == Decimal(100))
    }

    @Test func testUnitConverterStandardUnitsKeepRawPrice() {
        // 2 kg elma, birim fiyatı 40 TL, toplam 80 TL -> normalize kg fiyatı 40 TL kalmalı
        let normalizedKg = UnitConverter.normalizePriceToBaseUnit(
            totalPrice: Decimal(80),
            rawUnitPrice: Decimal(40),
            quantity: Decimal(2),
            unit: .kilogram
        )
        #expect(normalizedKg == Decimal(40))

        // 3 adet ekmek, birim fiyatı 10 TL, toplam 30 TL -> normalize adet fiyatı 10 TL kalmalı
        let normalizedPiece = UnitConverter.normalizePriceToBaseUnit(
            totalPrice: Decimal(30),
            rawUnitPrice: Decimal(10),
            quantity: Decimal(3),
            unit: .piece
        )
        #expect(normalizedPiece == Decimal(10))
    }

    @Test func testProductPackagingParserSingleUnits() {
        let kgResult = ProductPackagingParser.parse(from: "DOMATES SALKIM 1.5 KG")
        #expect(kgResult != nil)
        #expect(kgResult?.rawQuantity == Decimal(1.5))
        #expect(kgResult?.unit == .kilogram)
        #expect(kgResult?.packCount == 1)

        let gramResult = ProductPackagingParser.parse(from: "TAM YAGLI BEYAZ PEYNIR 500 GR")
        #expect(gramResult != nil)
        #expect(gramResult?.rawQuantity == Decimal(500))
        #expect(gramResult?.unit == .gram)
        #expect(gramResult?.packCount == 1)

        let literResult = ProductPackagingParser.parse(from: "UHT SUT 1 LT")
        #expect(literResult != nil)
        #expect(literResult?.rawQuantity == Decimal(1))
        #expect(literResult?.unit == .liter)
        #expect(literResult?.packCount == 1)
    }

    @Test func testProductPackagingParserMultiPack() {
        // "3x200ml MEYVE SUYU"
        let multiResult = ProductPackagingParser.parse(from: "3x200ml MEYVE SUYU")
        #expect(multiResult != nil)
        #expect(multiResult?.rawQuantity == Decimal(200))
        #expect(multiResult?.unit == .milliliter)
        #expect(multiResult?.packCount == 3)
    }

    @Test func testDTOInitializationAndSendable() {
        let item = ParsedItemDTO(
            rawName: "SUT 1LT",
            normalizedName: "Süt 1 L",
            quantity: Decimal(2),
            unit: .liter,
            unitPrice: Decimal(35),
            totalPrice: Decimal(70),
            taxRate: Decimal(0.01)
        )
        #expect(item.quantity == Decimal(2))
        #expect(item.totalPrice == Decimal(70))

        let receipt = ParsedReceiptDTO(
            storeName: "MİGROS",
            date: Date(),
            subtotal: Decimal(70),
            totalAmount: Decimal(70),
            taxTotal: Decimal(0.70),
            paymentMethod: .creditCard,
            items: [item]
        )
        #expect(receipt.storeName == "MİGROS")
        #expect(receipt.items.count == 1)
    }
}
