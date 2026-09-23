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
        parentCategory: Category? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isSystemDefault = isSystemDefault
        self.parentCategory = parentCategory
    }
}
