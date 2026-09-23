//
//  Store.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@Model
public final class Store {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var normalizedName: String
    public var branch: String?
    public var address: String?
    public var taxNumber: String?
    public var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ShoppingTrip.store)
    public var trips: [ShoppingTrip] = []

    public init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String,
        branch: String? = nil,
        address: String? = nil,
        taxNumber: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName
        self.branch = branch
        self.address = address
        self.taxNumber = taxNumber
        self.createdAt = createdAt
    }
}
