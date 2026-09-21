//
//  Item.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 21.09.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
