//
//  Category.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@Model
public final class Category {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var isSystemDefault: Bool
    public var rawCode: String?
    public var emoji: String?

    @Relationship(deleteRule: .nullify)
    public var parentCategory: Category?

    @Relationship(deleteRule: .cascade, inverse: \Category.parentCategory)
    public var subCategories: [Category] = []

    @Relationship(deleteRule: .nullify, inverse: \ShoppingItem.category)
    public var items: [ShoppingItem] = []

    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "cart.fill",
        colorHex: String = "#007AFF",
        isSystemDefault: Bool = false,
        rawCode: String? = nil,
        emoji: String? = nil,
        parentCategory: Category? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isSystemDefault = isSystemDefault
        self.rawCode = rawCode
        self.emoji = emoji
        self.parentCategory = parentCategory
    }

    public convenience init(standard: StandardCategory) {
        self.init(
            name: standard.displayName,
            iconName: standard.iconName,
            colorHex: standard.colorHex,
            isSystemDefault: true,
            rawCode: standard.rawCode,
            emoji: standard.emoji
        )
    }
}
