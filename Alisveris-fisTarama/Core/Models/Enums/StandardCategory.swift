//
//  StandardCategory.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 27.09.2026.
//

import Foundation

/// Fiş kalemleri için CoreML sınıflandırıcısıyla uyumlu 20 standart perakende kategorisi
public enum StandardCategory: String, CaseIterable, Sendable, Codable {
    case produce = "PRODUCE"
    case dairyBreakfast = "DAIRY_BREAKFAST"
    case meatPoultry = "MEAT_POULTRY"
    case seafood = "SEAFOOD"
    case bakery = "BAKERY"
    case pantryStaples = "PANTRY_STAPLES"
    case junkFoodSweets = "JUNK_FOOD_SWEETS"
    case carbonatedEnergyDrinks = "CARBONATED_ENERGY_DRINKS"
    case healthyBeverages = "HEALTHY_BEVERAGES"
    case alcohol = "ALCOHOL"
    case tobacco = "TOBACCO"
    case cleaningHousehold = "CLEANING_HOUSEHOLD"
    case paperHygiene = "PAPER_HYGIENE"
    case personalCareCosmetics = "PERSONAL_CARE_COSMETICS"
    case babyCare = "BABY_CARE"
    case petCare = "PET_CARE"
    case homeKitchen = "HOME_KITCHEN"
    case clothingTextile = "CLOTHING_TEXTILE"
    case healthFitness = "HEALTH_FITNESS"
    case otherNonFood = "OTHER_NONFOOD"

    public var rawCode: String {
        self.rawValue
    }

    public var displayName: String {
        switch self {
        case .produce: return "Meyve & Sebze"
        case .dairyBreakfast: return "Süt & Kahvaltılık"
        case .meatPoultry: return "Et & Tavuk"
        case .seafood: return "Balık & Deniz Ürünleri"
        case .bakery: return "Fırın & Ekmek"
        case .pantryStaples: return "Temel Gıda & Bakliyat"
        case .junkFoodSweets: return "Atıştırmalık & Tatlı"
        case .carbonatedEnergyDrinks: return "Gazlı & Enerji İçeceği"
        case .healthyBeverages: return "Su & Sağlıklı İçecek"
        case .alcohol: return "Alkollü İçecekler"
        case .tobacco: return "Tütün Ürünleri"
        case .cleaningHousehold: return "Ev & Temizlik"
        case .paperHygiene: return "Kağıt & Hijyen"
        case .personalCareCosmetics: return "Kişisel Bakım & Kozmetik"
        case .babyCare: return "Bebek Bakımı"
        case .petCare: return "Evcil Hayvan"
        case .homeKitchen: return "Ev & Mutfak Gereçleri"
        case .clothingTextile: return "Giyim & Tekstil"
        case .healthFitness: return "Sağlık & Spor"
        case .otherNonFood: return "Diğer / Poşet"
        }
    }

    public var emoji: String {
        switch self {
        case .produce: return "🍎"
        case .dairyBreakfast: return "🧀"
        case .meatPoultry: return "🥩"
        case .seafood: return "🐟"
        case .bakery: return "🥖"
        case .pantryStaples: return "🌾"
        case .junkFoodSweets: return "🍫"
        case .carbonatedEnergyDrinks: return "🥤"
        case .healthyBeverages: return "🧃"
        case .alcohol: return "🍷"
        case .tobacco: return "🚬"
        case .cleaningHousehold: return "🧼"
        case .paperHygiene: return "🧻"
        case .personalCareCosmetics: return "🧴"
        case .babyCare: return "🍼"
        case .petCare: return "🐾"
        case .homeKitchen: return "🍳"
        case .clothingTextile: return "👕"
        case .healthFitness: return "💊"
        case .otherNonFood: return "🛍️"
        }
    }

    public var iconName: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairyBreakfast: return "cup.and.saucer.fill"
        case .meatPoultry: return "fork.knife"
        case .seafood: return "fish.fill"
        case .bakery: return "birthday.cake.fill"
        case .pantryStaples: return "takeoutbag.and.cup.and.straw.fill"
        case .junkFoodSweets: return "popcorn.fill"
        case .carbonatedEnergyDrinks: return "waterbottle.fill"
        case .healthyBeverages: return "drop.fill"
        case .alcohol: return "wineglass.fill"
        case .tobacco: return "flame.fill"
        case .cleaningHousehold: return "bubbles.and.sparkles.fill"
        case .paperHygiene: return "toilet.fill"
        case .personalCareCosmetics: return "comb.fill"
        case .babyCare: return "stroller.fill"
        case .petCare: return "pawprint.fill"
        case .homeKitchen: return "frying.pan.fill"
        case .clothingTextile: return "tshirt.fill"
        case .healthFitness: return "cross.case.fill"
        case .otherNonFood: return "bag.fill"
        }
    }

    public var colorHex: String {
        switch self {
        case .produce: return "#34C759"
        case .dairyBreakfast: return "#FF9500"
        case .meatPoultry: return "#FF3B30"
        case .seafood: return "#007AFF"
        case .bakery: return "#A2845E"
        case .pantryStaples: return "#AF52DE"
        case .junkFoodSweets: return "#FF2D55"
        case .carbonatedEnergyDrinks: return "#5856D6"
        case .healthyBeverages: return "#32ADE6"
        case .alcohol: return "#8E44AD"
        case .tobacco: return "#7F8C8D"
        case .cleaningHousehold: return "#00C7BE"
        case .paperHygiene: return "#30B0C7"
        case .personalCareCosmetics: return "#FF6482"
        case .babyCare: return "#FFD60A"
        case .petCare: return "#BF5AF2"
        case .homeKitchen: return "#FF9F0A"
        case .clothingTextile: return "#5E5CE6"
        case .healthFitness: return "#30D158"
        case .otherNonFood: return "#8E8E93"
        }
    }

    public static func from(rawCode: String) -> StandardCategory {
        let normalized = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return StandardCategory(rawValue: normalized) ?? .otherNonFood
    }
}
